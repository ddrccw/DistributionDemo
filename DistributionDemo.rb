require 'cgi'
require 'yaml'
require 'WEBrick'
include WEBrick

module Edu901iPhone
  class Helper
    def self.compareVersion(v1, v2)
      begin
        info1 = v1.split('.')
        majorVer1 = info1[0]
        minorVer1 = info1[1]
        subMinorVer1 = info1[2]

        info2 = v2.split('.')
        majorVer2 = info2[0]
        minorVer2 = info2[1]
        subMinorVer2 = info2[2]

        if majorVer1 < majorVer2
          return true
        elsif majorVer1 == majorVer2
          if minorVer1 < minorVer2
            return true
          elsif minorVer1 == minorVer2
            if subMinorVer1 < subMinorVer2
              return true
            end
          end
        end
        return false
      rescue
        return false
      end
    end

    def self.compareBuildNumber(b1, b2)
      return (b1 < b2) ? true : false
    end
  end

  class PlistServlet < HTTPServlet::AbstractServlet
    def getPlist(resp)
      contents = File.read('/Users/Shared/WebServer/Documents/DistributionDemo/DistributionDemo.plist')
      resp.body = contents
    end
    private :getPlist
    def do_GET(req,resp)
      params = CGI::parse(req.query_string)
      info = YAML.load_file('/Users/Shared/WebServer/Documents/DistributionDemo/DistributionDemo.yml')
      result1 = Helper.compareVersion(params['v'][0], info['DistributionDemo']['Version'])
      result2 = Helper.compareBuildNumber(params['b'][0].to_i, info['DistributionDemo']['BuildNumber'].to_i)
      if result1
        getPlist(resp)
      elsif result2
        getPlist(resp)
      end
    end
  end

  class IpaServlet < HTTPServlet::AbstractServlet
    def do_GET(req,resp)
        contents = File.read('/Users/Shared/WebServer/Documents/DistributionDemo/DistributionDemo.ipa')
        resp.body = contents
    end
  end

  class CheckServlet < HTTPServlet::AbstractServlet
    def do_POST(req,resp)
      begin
        params = CGI::parse(req.body)
        info = YAML.load_file('/Users/Shared/WebServer/Documents/DistributionDemo/DistributionDemo.yml')
        result1 = Helper.compareVersion(params['v'][0], info['DistributionDemo']['Version'])
        result2 = Helper.compareBuildNumber(params['b'][0].to_i, info['DistributionDemo']['BuildNumber'].to_i)
        resp.status = 500
        if result1
          resp.status = 200
          resp.body = "{\"results\": {}}"
        elsif result2
          resp.status = 200
          resp.body = "{\"results\": {}}"
        end
      rescue => e
        puts e
        resp.status = 500
      end
    end
  end

  if $0 == __FILE__
    server = HTTPServer.new(:Port=>8881, :DocumentRoot => "/Users/Shared/WebServer/Documents")
    server.mount("/DistributionDemo/check", CheckServlet)
    server.mount("/DistributionDemo", PlistServlet)
    server.mount("/DistributionDemo/ipa", IpaServlet)
    trap("INT"){ server.shutdown }
    server.start
  end
end
