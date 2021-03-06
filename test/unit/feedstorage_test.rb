#
# rpodder, podcast catching client written in Ruby.
#
# Copyright (c) 2011 Anton Ivanov anton.al.ivanov(no spam)gmail.com
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

require 'rpodder/rpodder'
require 'test/unit'
require 'flexmock/test_unit'

class FeedFetcherTest < Test::Unit::TestCase
  
  #TODO: How to stub a static method with Flexmock rather than to do it explicitly?
  class File
    
    def self.exists?
      true
    end
  end

  def test_when_full_URL_is_provided_then_it_is_used_to_fetch_contents    
    @folder = "workfolder"
    @title = "title"
    @episodes = [episode("/episode1"), episode("/episode2"), episode("/episode3")]

    assert_will_download(["workfolder/title/episode1", "workfolder/title/episode2", "workfolder/title/episode3"])
  end
  
  def test_when_there_are_no_episodes_to_download_then_none_will_be_downloaded
    @folder = "workfolder"
    @title = "title"
    @episodes = []

    assert_will_download([])    
  end

  def test_when_there_is_no_title_then_episodes_will_be_stored_in_root_of_work_directory
    @folder = "workfolder"
    @title = nil
    @episodes = [episode("/episode1"), episode("/episode2"), episode("/episode3")]

    assert_will_download(["workfolder/episode1", "workfolder/episode2", "workfolder/episode3"])    
  end
  
  def test_when_episode_URL_does_not_include_forward_slash_then_file_name_is_same_as_episode_URL
    @folder = "workfolder"
    @title = "title"
    @episodes = [episode("episode1"), episode("episode2"), episode("episode3")]

    assert_will_download(["workfolder/title/episode1", "workfolder/title/episode2", "workfolder/title/episode3"])
  end
  
  def test_when_episode_URL_includes_symbols_before_last_forward_slash_then_file_name_does_not_include_these_symbols
    @folder = "workfolder"
    @title = "title"
    @episodes = [episode("blah/episode1"), episode("blah/blah/episode2"), episode("blah/blah/blah/episode3")]

    assert_will_download(["workfolder/title/episode1", "workfolder/title/episode2", "workfolder/title/episode3"])    
  end

  def test_when_use_episode_names_option_is_provided_then_downloaded_files_have_corresponding_names
    @folder = "workfolder"
    @title = "title"
    @episodes = [episode("/episode1", "name1"), episode("/episode2", "name2"), episode("/episode3", "name3")]

    assert_will_download(["workfolder/title/name1", "workfolder/title/name2", "workfolder/title/name3"],
      {:useEpisodeNames => true})
  end
  
  def test_when_use_episode_names_option_is_provided_and_server_files_have_extension_then_this_extension_is_preserved
    @folder = "workfolder"
    @title = "title"
    @episodes = [episode("/episode1.mp3", "name1"), episode("/episode2.mp3", "name2"), episode("/episode3.mp3", "name3")]

    assert_will_download(["workfolder/title/name1.mp3", "workfolder/title/name2.mp3", "workfolder/title/name3.mp3"],
      {:useEpisodeNames => true})
  end

  private 
  
  def episode(url, name = nil)
    RPodder::Episode.new(url, name)
  end
  
  def assert_will_download(downloadedFiles, opts = {})    
    feedReader = reader(@title, @episodes)
    feedDownloader = downloader(@episodes, downloadedFiles)
    storage = RPodder::FeedStorage.new(@folder, feedReader, feedDownloader, opts)
    storage.storeEpisodes
  end
  
  def reader(title, episodes)
    feedReader = flexmock("feedreader")
    feedReader.should_receive(:title).and_return(title)
    feedReader.should_receive(:episodes).and_return(episodes)
    feedReader
  end
  
  def downloader(episodes, downloadedFiles)
    downloader = flexmock("downloader")
    episodeURLs = episodes.map {|x| x.url}
    episodeURLs.zip(downloadedFiles).each do |episodeURL, downloadedFile|
       downloader.should_receive(:download).with(episodeURL, downloadedFile)     
    end
    downloader
  end
end