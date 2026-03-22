defmodule HgsBrain.IngestionTest do
  # covers: hgs_brain.ingestion.accepts_markdown
  # covers: hgs_brain.ingestion.segment_tagged
  # covers: hgs_brain.ingestion.embedded
  # covers: hgs_brain.ingestion.idempotent
  # covers: hgs_brain.ingestion_health.status_recorded
  # covers: hgs_brain.ingestion_health.last_successful_ingestion
  # covers: hgs_brain.ingestion_health.failures_visible
  # covers: hgs_brain.ingestion_health.source_change_detected
  # covers: hgs_brain.ingestion_health.reprocessing_supported
  # covers: hgs_brain.ingestion_source_metadata.origin_metadata
  # covers: hgs_brain.ingestion_source_metadata.display_name
  # covers: hgs_brain.ingestion_source_metadata.segment_recorded
  # covers: hgs_brain.ingestion_source_metadata.timestamps_recorded
  # covers: hgs_brain.ingestion_source_metadata.content_fingerprint
  # covers: hgs_brain.ingestion_source_metadata.source_chunk_separation
  # covers: hgs_brain.ingestion_source_metadata.frontmatter_preserved

  use HgsBrain.DataCase, async: true

  import Mox

  alias HgsBrain.Ingestion
  alias HgsBrain.IngestionRecord
  alias HgsBrain.Repo

  setup :verify_on_exit!

  describe "ingest_file/2" do
    test "passes the personal collection to arcana" do
      expect(HgsBrain.MockArcanaClient, :ingest_file, fn path, opts ->
        assert path == "/tmp/test.md"
        assert opts[:collection] == "personal"
        assert opts[:repo] == Repo
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      assert {:ok, _} = Ingestion.ingest_file("/tmp/test.md", :personal)
    end

    test "passes the work collection to arcana" do
      expect(HgsBrain.MockArcanaClient, :ingest_file, fn _path, opts ->
        assert opts[:collection] == "work"
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      assert {:ok, _} = Ingestion.ingest_file("/tmp/test.md", :work)
    end

    test "deletes an existing document at the same path before re-ingesting" do
      collection = Repo.insert!(%Arcana.Collection{name: "personal"})

      existing_doc =
        Repo.insert!(%Arcana.Document{
          content: "old content",
          file_path: "/tmp/notes.md",
          status: :completed,
          collection_id: collection.id
        })

      expect(HgsBrain.MockArcanaClient, :delete, fn id, opts ->
        assert id == existing_doc.id
        assert opts[:repo] == Repo
        :ok
      end)

      expect(HgsBrain.MockArcanaClient, :ingest_file, fn _path, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      assert {:ok, _} = Ingestion.ingest_file("/tmp/notes.md", :personal)
    end

    test "does not call delete when no existing document matches" do
      expect(HgsBrain.MockArcanaClient, :ingest_file, fn _path, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      # No :delete expectation — verify_on_exit! will catch unexpected calls
      assert {:ok, _} = Ingestion.ingest_file("/tmp/new.md", :personal)
    end

    test "propagates arcana errors" do
      expect(HgsBrain.MockArcanaClient, :ingest_file, fn _path, _opts ->
        {:error, :parse_failed}
      end)

      assert {:error, :parse_failed} = Ingestion.ingest_file("/tmp/bad.md", :personal)
    end
  end

  describe "list_documents/1" do
    test "returns documents for the given segment only" do
      personal_collection = Repo.insert!(%Arcana.Collection{name: "personal"})
      work_collection = Repo.insert!(%Arcana.Collection{name: "work"})

      Repo.insert!(%Arcana.Document{
        content: "personal note",
        file_path: "/tmp/personal.md",
        status: :completed,
        collection_id: personal_collection.id
      })

      Repo.insert!(%Arcana.Document{
        content: "work note",
        file_path: "/tmp/work.md",
        status: :completed,
        collection_id: work_collection.id
      })

      personal_docs = Ingestion.list_documents(:personal)
      assert length(personal_docs) == 1
      assert hd(personal_docs).file_path == "/tmp/personal.md"

      work_docs = Ingestion.list_documents(:work)
      assert length(work_docs) == 1
      assert hd(work_docs).file_path == "/tmp/work.md"
    end

    test "returns empty list when segment has no documents" do
      assert [] = Ingestion.list_documents(:work)
    end
  end

  describe "delete_document/1" do
    test "delegates to arcana with the repo" do
      doc_id = Ecto.UUID.generate()

      expect(HgsBrain.MockArcanaClient, :delete, fn id, opts ->
        assert id == doc_id
        assert opts[:repo] == Repo
        :ok
      end)

      assert :ok = Ingestion.delete_document(doc_id)
    end
  end

  describe "ingestion health" do
    setup do
      path = Path.join(System.tmp_dir!(), "hgs_brain_test_#{System.unique_integer()}.md")
      File.write!(path, "# Test\n\nSome content.")
      on_exit(fn -> File.rm(path) end)
      %{path: path}
    end

    test "records ok status after successful ingestion", %{path: path} do
      expect(HgsBrain.MockArcanaClient, :ingest_file, fn _path, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      assert {:ok, _} = Ingestion.ingest_file(path, :personal)

      record = Ingestion.ingestion_health(path, :personal)
      assert record.status == :ok
      assert record.error_reason == nil
    end

    test "records ingested_at timestamp after successful ingestion", %{path: path} do
      before = DateTime.utc_now() |> DateTime.truncate(:second)

      expect(HgsBrain.MockArcanaClient, :ingest_file, fn _path, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      Ingestion.ingest_file(path, :personal)

      record = Ingestion.ingestion_health(path, :personal)
      assert DateTime.compare(record.ingested_at, before) in [:gt, :eq]
    end

    test "records error status and reason after failed ingestion", %{path: path} do
      expect(HgsBrain.MockArcanaClient, :ingest_file, fn _path, _opts ->
        {:error, :parse_failed}
      end)

      assert {:error, :parse_failed} = Ingestion.ingest_file(path, :personal)

      record = Ingestion.ingestion_health(path, :personal)
      assert record.status == :error
      assert record.error_reason =~ "parse_failed"
    end

    test "source_changed? returns false when file unchanged since last successful ingestion",
         %{path: path} do
      expect(HgsBrain.MockArcanaClient, :ingest_file, fn _path, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      Ingestion.ingest_file(path, :personal)

      refute Ingestion.source_changed?(path, :personal)
    end

    test "source_changed? returns true when file content changes after ingestion", %{path: path} do
      expect(HgsBrain.MockArcanaClient, :ingest_file, fn _path, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      Ingestion.ingest_file(path, :personal)

      File.write!(path, "# Updated\n\nDifferent content.")

      assert Ingestion.source_changed?(path, :personal)
    end

    test "source_changed? returns true when no health record exists", %{path: path} do
      assert Ingestion.source_changed?(path, :personal)
    end

    test "updates health record on reprocessing after failure", %{path: path} do
      expect(HgsBrain.MockArcanaClient, :ingest_file, fn _path, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      # Simulate a failed prior health record
      Repo.insert!(%IngestionRecord{
        file_path: path,
        segment: "personal",
        status: :error,
        error_reason: "prior failure"
      })

      assert Ingestion.source_changed?(path, :personal)

      Ingestion.ingest_file(path, :personal)

      record = Ingestion.ingestion_health(path, :personal)
      assert record.status == :ok
      refute Ingestion.source_changed?(path, :personal)
    end
  end

  describe "ingestion source metadata" do
    setup do
      path = Path.join(System.tmp_dir!(), "hgs_brain_meta_test_#{System.unique_integer()}.md")
      on_exit(fn -> File.rm(path) end)
      %{path: path}
    end

    test "stores the file path as origin metadata", %{path: path} do
      File.write!(path, "# Hello\n\nContent.")

      expect(HgsBrain.MockArcanaClient, :ingest_file, fn _path, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      Ingestion.ingest_file(path, :personal)

      record = Ingestion.ingestion_health(path, :personal)
      assert record.file_path == path
    end

    test "stores the segment as metadata", %{path: path} do
      File.write!(path, "# Hello\n\nContent.")

      expect(HgsBrain.MockArcanaClient, :ingest_file, fn _path, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      Ingestion.ingest_file(path, :work)

      record = Ingestion.ingestion_health(path, :work)
      assert record.segment == "work"
    end

    test "derives display title from frontmatter when present", %{path: path} do
      File.write!(path, "---\ntitle: My Knowledge Note\n---\n\nContent.")

      expect(HgsBrain.MockArcanaClient, :ingest_file, fn _path, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      Ingestion.ingest_file(path, :personal)

      record = Ingestion.ingestion_health(path, :personal)
      assert record.title == "My Knowledge Note"
    end

    test "derives display title from filename when no frontmatter", %{path: _path} do
      named_path = Path.join(System.tmp_dir!(), "my_work_notes.md")
      File.write!(named_path, "# Hello\n\nContent.")
      on_exit(fn -> File.rm(named_path) end)

      expect(HgsBrain.MockArcanaClient, :ingest_file, fn _path, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      Ingestion.ingest_file(named_path, :personal)

      record = Ingestion.ingestion_health(named_path, :personal)
      assert record.title == "My work notes"
    end

    test "stores document_id linking source to arcana chunks", %{path: path} do
      doc_id = Ecto.UUID.generate()
      File.write!(path, "# Hello\n\nContent.")

      expect(HgsBrain.MockArcanaClient, :ingest_file, fn _path, _opts ->
        {:ok, %{id: doc_id}}
      end)

      Ingestion.ingest_file(path, :personal)

      record = Ingestion.ingestion_health(path, :personal)
      assert record.document_id == doc_id
    end

    test "preserves frontmatter as structured metadata", %{path: path} do
      File.write!(path, "---\ntitle: My Note\ntags: work elixir\n---\n\nContent.")

      expect(HgsBrain.MockArcanaClient, :ingest_file, fn _path, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      Ingestion.ingest_file(path, :personal)

      record = Ingestion.ingestion_health(path, :personal)
      assert record.frontmatter["title"] == "My Note"
      assert record.frontmatter["tags"] == "work elixir"
    end

    test "stores nil frontmatter when none present", %{path: path} do
      File.write!(path, "# Hello\n\nNo frontmatter.")

      expect(HgsBrain.MockArcanaClient, :ingest_file, fn _path, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      Ingestion.ingest_file(path, :personal)

      record = Ingestion.ingestion_health(path, :personal)
      assert record.frontmatter == nil
    end

    test "records timestamps distinguishing initial ingestion from updates", %{path: path} do
      File.write!(path, "# Hello\n\nContent.")

      expect(HgsBrain.MockArcanaClient, :ingest_file, 2, fn _path, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      Ingestion.ingest_file(path, :personal)
      first_record = Ingestion.ingestion_health(path, :personal)

      File.write!(path, "# Hello\n\nUpdated content.")
      Ingestion.ingest_file(path, :personal)
      second_record = Ingestion.ingestion_health(path, :personal)

      assert first_record.inserted_at == second_record.inserted_at

      assert NaiveDateTime.compare(second_record.updated_at, first_record.updated_at) in [
               :gt,
               :eq
             ]
    end
  end
end
