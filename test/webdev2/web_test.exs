defmodule Webdev2.WebTest do
  use Webdev2.DataCase

  alias Webdev2.Web

  describe "sites" do
    alias Webdev2.Web.Site

    @valid_attrs %{body: "some body", tags: "some tags", title: "some title", url: "some url"}
    @update_attrs %{body: "some updated body", tags: "some updated tags", title: "some updated title", url: "some updated url"}
    @invalid_attrs %{body: nil, tags: nil, title: nil, url: nil}

    def site_fixture(attrs \\ %{}) do
      {:ok, site} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Web.create_site()

      site
    end

    test "list_sites/0 returns all sites" do
      site = site_fixture()
      assert Web.list_sites() == [site]
    end

    test "get_site!/1 returns the site with given id" do
      site = site_fixture()
      assert Web.get_site!(site.id) == site
    end

    test "create_site/1 with valid data creates a site" do
      assert {:ok, %Site{} = site} = Web.create_site(@valid_attrs)
      assert site.body == "some body"
      assert site.tags == "some tags"
      assert site.title == "some title"
      assert site.url == "some url"
    end

    test "create_site/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Web.create_site(@invalid_attrs)
    end

    test "update_site/2 with valid data updates the site" do
      site = site_fixture()
      assert {:ok, %Site{} = site} = Web.update_site(site, @update_attrs)
      assert site.body == "some updated body"
      assert site.tags == "some updated tags"
      assert site.title == "some updated title"
      assert site.url == "some updated url"
    end

    test "update_site/2 with invalid data returns error changeset" do
      site = site_fixture()
      assert {:error, %Ecto.Changeset{}} = Web.update_site(site, @invalid_attrs)
      assert site == Web.get_site!(site.id)
    end

    test "delete_site/1 deletes the site" do
      site = site_fixture()
      assert {:ok, %Site{}} = Web.delete_site(site)
      assert_raise Ecto.NoResultsError, fn -> Web.get_site!(site.id) end
    end

    test "change_site/1 returns a site changeset" do
      site = site_fixture()
      assert %Ecto.Changeset{} = Web.change_site(site)
    end
  end
end
