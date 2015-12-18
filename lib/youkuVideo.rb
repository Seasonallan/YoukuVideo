require "youkuVideo/version"
require "base64"
require "uri"
require "rest-client"

module YoukuVideo
  class M3U8
    def self.youkuEncoder(a, c, isToBase64)
      result = ""
      bytesR = []
      f,h,q = 0,0,0
      b = []
      256.times{|i| b[i]=i}
      while h < 256 do
        f = (f + b[h] + a[h % a.length].ord) % 256
        tmp = b[h]
        b[h] = b[f]
        b[f] = tmp
        h += 1
      end
      f,h,q = 0,0,0
      while q < c.length
        h = (h + 1) % 256
        f = (f + b[h]) % 256
        tmp = b[h]
        b[h] = b[f]
        b[f] = tmp
        bytes = [c[q].ord ^ b[(b[h] + b[f]) % 256]].pack "l"
        bytesR.push(bytes[0])
        result += bytes[0]
        q += 1
      end
      if isToBase64
        result = Base64.encode64(bytesR.join(""))
      end
      return result
    end

    def self.getEp(vid, ep)
      template1 = "becaf9be"
      template2 = "bf7e5f01"
      bytes = Base64.decode64(ep).split(//)
      tmp = youkuEncoder(template1, bytes, false)
      sid = tmp.split("_")[0]
      token = tmp.split("_")[1]
      whole = "#{sid}_#{vid}_#{token}"
      newbytes = whole.split("").map { |e| e.ord }
      epNew = youkuEncoder(template2, newbytes, true)
      return URI.encode(epNew), sid, token
    end

    def self.getVideoURL(url, type)
      matches = /id_([a-zA-Z0-9]*)/.match url
      if !matches.nil?
        vid = matches[1]
        content = RestClient.get("http://play.youku.com/play/get.json?vid=#{vid}&ct=12", :referer => 'http://static.youku.com')
        cookie_r = ""
        unless content.cookies.nil?
          cookie_r = content.cookies['r']
        end
        json = JSON.parse(content)
        ip = json["data"]["security"]["ip"]
        ep = json["data"]["security"]["encrypt_string"]
        ep,sid,token = getEp(vid, ep)
        return "http://pl.youku.com/playlist/m3u8?ctype=12&ep=#{ep}&ev=1&keyframe=1&oip=#{ip}&sid=#{sid}&token=#{token}&vid=#{vid}&type=#{type}", cookie_r
      else
        return "", ""
      end
    end
  end
end
