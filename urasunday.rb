#coding:utf-8
require 'open-uri'
require 'nokogiri'
require './test/test_data'
require "rss/maker"
class Urasunday
  attr_accessor :titles,:mangas,:sorted_mangas,:feed
  def initialize
    @base_url = "http://urasunday.com"
    @html = self.get_html()
    @charset = "utf-8"
    @titles = self.get_manga_title()
    test = TestData.new
    @mangas = test.test_data()
    @sorted_mangas = self.updatead_sort()
    @feed = self.create_feed()
    self.create_rss_file()
    #@mangas = self.get_mangas_info()
  end
  #urlを取得してdocに保存する
  def get_html(url="")
    url = @base_url if url.empty? 
    html = open(url) do |f|
      #@charset = f.charset
      f.read
    end
    return html
  end
  def get_manga_title
    titles = Hash.new
    doc = Nokogiri::HTML.parse(@html, nil, @charset)
    doc.css(".indexComicDetailComicTitle").each do |title|
      title_url = title.css("a").attribute("href").content
      title_url.gsub!(/\.|\/|index|html/,"")
      titles[title_url] = title.content
    end
    return titles
  end
  def get_mangas_info
    mangas = Hash.new
    @titles.each do |id,title|
      mangas[id] = Array.new
      manga_url = "http://urasunday.com/"+id
      html = self.get_html(manga_url)
      doc = Nokogiri::HTML.parse(html, nil, @charset)
      #話へのリンクを持つ要素全部を探す
      (1..100).each do |num|
        episode_elements = doc.css(".cNum0"+num.to_s)
        break if episode_elements.empty?
        #要素一個
        episode_elements.each do |episode_element|
          #話数を取得
          episode_num = episode_element.parent.parent.css(".detailComicDetailNLT02NumberBoxH").css("p").text.gsub!(/\D/,"")
          #話数が無かったらスキップ(PRコミックなど)
          next if episode_num.empty?
          url = "http://urasunday.com/"+id+"/"+episode_element.attribute("href").content
          #ここで各１話ずつの更新情報とタイトルを取得
          manga_info = self.get_manga_info(url)
          mangas[id] << manga_info if manga_info
        end
      end
    end

    return mangas
  end
  def get_manga_info(url="")
    return false if url.empty?
    info = Hash.new
    html = self.get_html(url)
    doc = Nokogiri::HTML.parse(html, nil, @charset)
    title_data = doc.css(".comicTitleDate").text.split("｜")
    return false if title_data.empty?
    detail = doc.css("#comicDetail")
    info['title'] = detail.css("h1").text
    info['author'] = detail.css("h2").text
    info['num'] = title_data[0].strip
    info['updated_at'] = title_data[1].strip.gsub!(/更新/,"").gsub!(/\//,"-")
    info['url'] = url
    return info
  end
  def updatead_sort
    sorted_mangas = Array.new
    @mangas.each do |title,episodes|
      sorted_mangas.concat episodes
    end
    sorted_mangas.sort! do |a,b|
      a["updated_at"] <=> b["updated_at"]
    end
    return sorted_mangas
  end
  def create_feed
    link = "http://www.u.tsukuba.ac.jp/~s1321645/urasunday.xml"
    RSS::Maker.make("2.0") do |rss|
      rss.channel.title = "裏サンデー"
      rss.channel.description = "裏サンデーのRSSです"
      rss.channel.link = link 
      rss.channel.about = link 
      @sorted_mangas.each do |manga|
        item = rss.items.new_item
        item.title = manga['title']+" "+manga['num']
        item.link = manga['url']
      end
=begin
      rss.channel.title = "present"
      rss.channel.description = "feed sample"
      rss.channel.link = link 
      rss.channel.about = link 
      1.upto(5) do |i|
        item = rss.items.new_item
        item.title = "entry#{i}"
        item.link = link + "/entry/#{i}"
      end
=end
    end.to_s
  end
  def create_rss_file
    # ファイルに書き出し
    output_file = File.open("urasunday.rss", "w")    # 書き込み専用でファイルを開く（新規作成）
    output_file.write(@feed)    # ファイルにデータ書き込み
    output_file.close        # ファイルクローズ
  end
end
