
#coding: utf-8

namespace :parse do
	desc "Parsing!"

	root_url = "http://kino.kz"

	task :cities => :environment do
		require "nokogiri"
		require "open-uri"
		require 'json'

		html = Nokogiri::HTML(open("http://kino.kz/new/schedule"))
		html.css("#city-select option").each do |city|
			City.create(name: city.text, kinokz_id: city["value"])
		end
	end

	task :cinemas => :environment do
		require "nokogiri"
		require "open-uri"

		City.all.each do |city|
			html = Nokogiri::HTML(open("http://kino.kz/new/list_cinemas?city=#{city.kinokz_id}"), nil, "UTF-8").css("p")
			cinemas_json = JSON.parse(html.text)

			cinemas_json.each do |cinema|
				city.cinemas.create(name: cinema["name"], kinokz_id: cinema["id"])
			end
		end
	end

	task :sessions_movies => :environment do
		require "nokogiri"
		require "open-uri"

		Cinema.all.each do |cinema|
			html = Nokogiri::HTML(open("http://kino.kz/new/schedule_cinema?id=#{cinema.kinokz_id}&sort=0&day=0&startTime=00%3A01&endTime=23%3A59"), nil, "UTF-8")
			puts "Opening http://kino.kz/new/schedule_cinema?id=#{cinema.kinokz_id}&sort=0&day=0&startTime=00%3A01&endTime=23%3A59"

			if html.css("table").count > 0
				temp_arr_for_movies_id = []

				html.css("table").each do |movie|
					movie_id = movie.css("a[href]")[0]["href"].scan(/\d+/).first
					temp_arr_for_movies_id.push(movie_id)

					if !Movie.exists?(kinokz_id: movie_id)
						movie_title = movie.css(".title").text
						movie_img_src = movie.css("img")[0]["src"]
						html_movie = Nokogiri::HTML(open(root_url + movie.css("a[href]")[0]["href"]), nil, "UTF-8")
						movie_desc = html_movie.css(".story p").text

						Movie.create(title: movie_title, description: movie_desc, image_url: movie_img_src, kinokz_id: movie_id)
					end
				end

				for i in 0...temp_arr_for_movies_id.length - 1
					sessions_part = html.to_s[html.to_s.index("new/movie/#{temp_arr_for_movies_id[i]}")..html.to_s.index("new/movie/#{temp_arr_for_movies_id[i + 1]}")]
					sessions_html = Nokogiri::HTML(sessions_part)

					sessions_html.css(".txt-rounded").each do |session|
						Movie.find_by(kinokz_id: temp_arr_for_movies_id[i]).sessions.create(cinema_id: cinema.kinokz_id, time: session.text)
					end
				end

				sessions_part_for_last = html.to_s[html.to_s.index("new/movie/#{temp_arr_for_movies_id[temp_arr_for_movies_id.length - 1]}")..html.to_s.length - 1]
				sessions_html_for_last = Nokogiri::HTML(sessions_part_for_last)

				sessions_html_for_last.css(".txt-rounded").each do |session|
					Movie.find_by(kinokz_id: temp_arr_for_movies_id[temp_arr_for_movies_id.length - 1]).sessions.create(cinema_id: cinema.kinokz_id, time: session.text)
				end

				temp_arr_for_movies_id = []
			else
				puts "skipping"
			end
		end
	end
end
