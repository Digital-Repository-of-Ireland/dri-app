require 'digest'

module Checksum

  def self.checksum(algorithm, filename)
    case algorithm
      when "md5"
        md5(filename)
      when "sha256"
        sha256(filename)
      when "rmd160"
        rmd160(filename)
    end 
  end

  def self.md5(filename)
    puts "Filename: #{filename}"
    Digest::MD5.file(filename).hexdigest
  end

  def self.sha256(filename)
    Digest::SHA256.file(filename).hexdigest
  end

  def self.rmd160(filename)
    Digest::RMD160.file(filename).hexdigest
  end

end
