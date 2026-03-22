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
end
