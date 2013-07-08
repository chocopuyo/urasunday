#coding:utf-8
require 'rss'
require File.expand_path(File.dirname(__FILE__))+'/../urasunday'
describe Urasunday, "掲載マンガのRSSを生成" do
  before :all do
    @urasunday = Urasunday.new
  end
  it "掲載マンガの情報とそのURLを取得" do
    mangas = @urasunday.titles
    expect(mangas).to be_an_instance_of(Hash)
    manga_url = mangas[mangas.keys.first]
    expect(manga_url).to match /\S+/
    expect(mangas.keys.first).to match /\S+/
  end
  it "特定のマンガの情報を取得" do
    mangas = @urasunday.mangas
    #mangas = {"title"=>
    #  [{"url"=>"019_001","num"=>"19","sub_num"=>"1","updated_at"=>"20130614"},
    #    {"url"=>"019_002","num"=>"19","sub_num"=>"2","updated_at"=>"20130621"}
    #  ]}
    expect(mangas).to have_at_least(1).items
    manga = mangas[mangas.keys.first]
    expect(manga[0]["url"]).not_to be_empty
    expect(manga[0]["num"]).not_to be_empty
    expect(manga[0]["author"]).not_to be_empty
    expect(manga[0]["updated_at"]).not_to be_empty
  end
  it "RSSで加工しやすいように、更新順の配列に変更" do
  mangas = @urasunday.sorted_mangas
    mangas.each_with_index do |manga,index|
      expect(manga['updated_at']).to be <= mangas[index-1]['updated_at'] if mangas[index-1]['updated_at']&&index-1>=0
      expect(manga['updated_at']).to be >= mangas[index+1]['updated_at'] if manga.class == Array&&mangas[index+1]['updated_at']
    end
  end
  it "加工した情報をRSSに変更" do
  feed = @urasunday.feed
  rss = RSS::Parser.parse(feed, true)
  expect(rss).to be_true
  end

end
