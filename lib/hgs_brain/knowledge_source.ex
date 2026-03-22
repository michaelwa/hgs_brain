defmodule HgsBrain.KnowledgeSource do
  @moduledoc """
  Value struct representing a normalized knowledge source before downstream
  ingestion processing.

  Both markdown files and quick captures are normalized into this struct,
  establishing a common ingestion contract regardless of source type.

  <!-- covers: hgs_brain.knowledge_source_ingestion.multiple_source_types -->
  <!-- covers: hgs_brain.knowledge_source_ingestion.normalized_source_record -->
  <!-- covers: hgs_brain.knowledge_source_ingestion.segment_preserved -->
  <!-- covers: hgs_brain.knowledge_source_ingestion.extracts_ingestible_content -->
  <!-- covers: hgs_brain.knowledge_source_ingestion.retrieval_eligibility -->
  <!-- covers: hgs_brain.knowledge_source_ingestion.processing_failure_visible -->
  """

  @type source_type :: :markdown_file | :capture

  @type t :: %__MODULE__{
          source_type: source_type(),
          segment: String.t(),
          content: String.t() | nil,
          file_path: String.t() | nil,
          title: String.t() | nil,
          frontmatter: map() | nil,
          origin_type: String.t()
        }

  @enforce_keys [:source_type, :segment, :origin_type]
  defstruct [:source_type, :segment, :content, :file_path, :title, :frontmatter, :origin_type]

  @doc """
  Builds a KnowledgeSource from a markdown file path and segment.

  Reads the file for metadata extraction (frontmatter, display title).
  File content for chunking is handled by arcana via the file path.
  """
  @spec from_file(Path.t(), atom()) :: t()
  def from_file(path, segment) when segment in [:work, :personal] do
    {title, frontmatter} = extract_file_metadata(path)

    %__MODULE__{
      source_type: :markdown_file,
      segment: Atom.to_string(segment),
      content: nil,
      file_path: path,
      title: title,
      frontmatter: frontmatter,
      origin_type: "markdown_file"
    }
  end

  @doc """
  Builds a KnowledgeSource from freeform capture text and segment.
  """
  @spec from_capture(String.t(), atom()) :: t()
  def from_capture(text, segment) when segment in [:work, :personal] and is_binary(text) do
    %__MODULE__{
      source_type: :capture,
      segment: Atom.to_string(segment),
      content: text,
      file_path: nil,
      title: nil,
      frontmatter: nil,
      origin_type: "quick_text"
    }
  end

  defp extract_file_metadata(path) do
    case File.read(path) do
      {:ok, content} ->
        frontmatter = parse_frontmatter(content)
        title = (frontmatter && Map.get(frontmatter, "title")) || derive_title(path)
        {title, frontmatter}

      {:error, _} ->
        {derive_title(path), nil}
    end
  end

  defp parse_frontmatter(content) do
    case Regex.run(~r/\A---\n(.*?)\n---(\n|\z)/s, content, capture: :all_but_first) do
      [yaml | _] -> parse_yaml_kv(yaml)
      nil -> nil
    end
  end

  defp parse_yaml_kv(yaml) do
    result =
      yaml
      |> String.split("\n")
      |> Enum.reduce(%{}, fn line, acc ->
        case Regex.run(~r/^([^:]+):\s*(.+)$/, String.trim(line)) do
          [_, key, value] -> Map.put(acc, String.trim(key), String.trim(value))
          _ -> acc
        end
      end)

    if map_size(result) == 0, do: nil, else: result
  end

  defp derive_title(path) do
    base = Path.basename(path, Path.extname(path))
    humanized = String.replace(base, ~r/[-_]+/, " ")
    String.upcase(String.first(humanized)) <> String.slice(humanized, 1..-1//1)
  end
end
