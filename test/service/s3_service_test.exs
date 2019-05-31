defmodule ActivestorageExTest.S3ServiceTest do
  use ExUnit.Case
  doctest ActivestorageEx.S3Service
  alias ActivestorageEx.S3Service

  @test_key "testing_key"

  describe "S3Service.download/1" do
    test "Returns a file from a given key as binary" do
      upload_test_image()

      downloaded_file = S3Service.download(@test_key)

      assert is_binary(downloaded_file)

      delete_test_image()
    end

    test "Returns an error if the file cannot be found" do
      missing_file = S3Service.download("fake_key")

      assert {:error, :not_found} == missing_file
    end
  end

  describe "S3Service.stream_download/2" do
    test "An image is downloaded to the given filepath" do
      upload_test_image()

      filepath = "test/files/streamed.jpg"
      S3Service.stream_download(@test_key, filepath)

      assert File.exists?(filepath)

      File.rm(filepath)
      delete_test_image()
    end

    test "The filepath is returned upon success" do
      upload_test_image()

      filepath = "test/files/streamed.jpg"
      download = S3Service.stream_download(@test_key, filepath)

      assert {:ok, ^filepath} = download

      File.rm(filepath)
      delete_test_image()
    end
  end

  describe "S3Service.upload/2" do
    test "An image is sucessfully saved to s3" do
      image = Mogrify.open("test/files/image.jpg")

      S3Service.upload(image, @test_key)

      assert S3Service.exist?(@test_key)

      delete_test_image()
    end

    test "An image with a complex path is sucessfully saved to s3" do
      image = Mogrify.open("test/files/image.jpg")
      key = "variants/new_key"

      S3Service.upload(image, key)

      assert S3Service.exist?(key)

      delete_test_image()
    end
  end

  describe "S3Service.delete/1" do
    test "An image is sucessfully deleted from s3" do
      upload_test_image()

      assert S3Service.exist?(@test_key)

      S3Service.delete(@test_key)

      refute S3Service.exist?(@test_key)
    end

    test "An image with a complex path is sucessfully deleted from s3" do
      upload_test_image()

      assert S3Service.exist?(@test_key)

      S3Service.delete(@test_key)

      refute S3Service.exist?(@test_key)
    end
  end

  describe "S3Service.url/2" do
    test "The full disposition is present in the final URL" do
      url =
        S3Service.url(@test_key, %{
          filename: @test_key,
          disposition: "inline"
        })

      assert String.contains?(
               url,
               "response_content_disposition=inline%3B%20filename%3D%22testing_key%22"
             )
    end

    test "The filename is present in the final URL" do
      url_path =
        S3Service.url(@test_key, %{
          filename: @test_key,
          disposition: "inline"
        })
        |> String.split("/")
        |> Enum.at(4)

      assert String.starts_with?(url_path, @test_key)
    end

    test "The expiration is present in the final URL" do
      Application.put_env(:activestorage_ex, :link_expiration, 100)

      url =
        S3Service.url(@test_key, %{
          filename: @test_key,
          disposition: "inline"
        })

      assert String.contains?(url, "X-Amz-Expires=100")

      Application.put_env(:activestorage_ex, :link_expiration, 5 * 60)
    end
  end

  describe "S3Service.exist?/1" do
    test "Returns true if a file with a given key exists" do
      upload_test_image()

      assert S3Service.exist?(@test_key)

      delete_test_image()
    end

    test "Returns false if a file with a given key doesn't exist" do
      refute S3Service.exist?("not-a-real-key")
    end
  end

  defp upload_test_image() do
    image = Mogrify.open("test/files/image.jpg")

    S3Service.upload(image, @test_key)

    @test_key
  end

  defp delete_test_image() do
    S3Service.delete(@test_key)

    @test_key
  end
end
