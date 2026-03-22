defmodule HgsBrain.KnowledgeSourceIngestionTest do
  # covers: hgs_brain.knowledge_source_ingestion.multiple_source_types
  # covers: hgs_brain.knowledge_source_ingestion.normalized_source_record
  # covers: hgs_brain.knowledge_source_ingestion.segment_preserved
  # covers: hgs_brain.knowledge_source_ingestion.extracts_ingestible_content
  # covers: hgs_brain.knowledge_source_ingestion.retrieval_eligibility
  # covers: hgs_brain.knowledge_source_ingestion.processing_failure_visible

  use HgsBrain.DataCase, async: true

  import Mox

  alias HgsBrain.{KnowledgeSource, Ingestion, Captures}

  setup :verify_on_exit!

  describe "KnowledgeSource contract" do
    test "from_file and from_capture produce the same struct type" do
      path = write_temp_file("# Hello\n\nContent.")

      file_source = KnowledgeSource.from_file(path, :personal)
      capture_source = KnowledgeSource.from_capture("A capture.", :personal)

      assert %KnowledgeSource{} = file_source
      assert %KnowledgeSource{} = capture_source

      File.rm(path)
    end

    test "both source types carry segment as a common field" do
      path = write_temp_file("# Note\n\nContent.")

      file_source = KnowledgeSource.from_file(path, :work)
      capture_source = KnowledgeSource.from_capture("Work capture.", :work)

      assert file_source.segment == "work"
      assert capture_source.segment == "work"

      File.rm(path)
    end

    test "both source types carry origin_type as a common field" do
      path = write_temp_file("# Note\n\nContent.")

      file_source = KnowledgeSource.from_file(path, :personal)
      capture_source = KnowledgeSource.from_capture("Quick thought.", :personal)

      assert is_binary(file_source.origin_type)
      assert is_binary(capture_source.origin_type)

      File.rm(path)
    end

    test "file source identifies itself as markdown_file" do
      path = write_temp_file("# Note\n\nContent.")
      source = KnowledgeSource.from_file(path, :personal)
      assert source.source_type == :markdown_file
      File.rm(path)
    end

    test "capture source identifies itself as capture" do
      source = KnowledgeSource.from_capture("A thought.", :personal)
      assert source.source_type == :capture
    end

    test "file source carries the file path for arcana to extract content" do
      path = write_temp_file("# Note\n\nContent.")
      source = KnowledgeSource.from_file(path, :personal)
      assert source.file_path == path
      File.rm(path)
    end

    test "capture source carries ingestible text content" do
      source = KnowledgeSource.from_capture("Extractable content.", :personal)
      assert source.content == "Extractable content."
    end

    test "file source extracts frontmatter as structured metadata" do
      path = write_temp_file("---\ntitle: Meeting Notes\n---\n\nContent.")
      source = KnowledgeSource.from_file(path, :personal)
      assert source.title == "Meeting Notes"
      assert source.frontmatter["title"] == "Meeting Notes"
      File.rm(path)
    end
  end

  describe "multiple source types through the ingestion pipeline" do
    setup do
      path = write_temp_file("# File Source\n\nSome content.")
      on_exit(fn -> File.rm(path) end)
      %{path: path}
    end

    test "file source is retrievable after ingestion", %{path: path} do
      expect(HgsBrain.MockArcanaClient, :ingest_file, fn _path, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      assert {:ok, _} = Ingestion.ingest_file(path, :personal)
    end

    test "capture source is retrievable after ingestion" do
      expect(HgsBrain.MockArcanaClient, :ingest, fn _text, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      assert {:ok, capture} = Captures.create_capture("A retrievable thought.", :personal)
      assert capture.document_id != nil
    end

    test "segment is preserved through file ingestion pipeline", %{path: path} do
      expect(HgsBrain.MockArcanaClient, :ingest_file, fn _path, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      Ingestion.ingest_file(path, :work)
      record = Ingestion.ingestion_health(path, :work)
      assert record.segment == "work"
    end

    test "segment is preserved through capture ingestion pipeline" do
      expect(HgsBrain.MockArcanaClient, :ingest, fn _text, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      {:ok, capture} = Captures.create_capture("Work thought.", :work)
      assert capture.segment == "work"
    end

    test "file ingestion failure is visible through ingestion health record", %{path: path} do
      expect(HgsBrain.MockArcanaClient, :ingest_file, fn _path, _opts ->
        {:error, :parse_failed}
      end)

      assert {:error, :parse_failed} = Ingestion.ingest_file(path, :personal)

      record = Ingestion.ingestion_health(path, :personal)
      assert record.status == :error
      assert record.error_reason =~ "parse_failed"
    end

    test "capture creation failure is returned as inspectable error" do
      assert {:error, changeset} = Captures.create_capture("", :personal)
      assert changeset.errors[:content]
    end
  end

  defp write_temp_file(content) do
    path = Path.join(System.tmp_dir!(), "ks_test_#{System.unique_integer()}.md")
    File.write!(path, content)
    path
  end
end
