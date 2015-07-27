require 'digest'
# Generate various checksums
module Checksum
  def self.checksum(algorithm, filename)
    case algorithm
    when 'md5'
      md5(filename)
    when 'sha256'
      sha256(filename)
    when 'rmd160'
      rmd160(filename)
    else
      sha256(filename) # default to sha256 if unknown
    end
  end

  def self.md5_string(string)
    Digest::MD5.hexdigest(string)
  end

  def self.md5(filename)
    Digest::MD5.file(filename).hexdigest
  end

  def self.sha256(filename)
    Digest::SHA256.file(filename).hexdigest
  end

  def self.rmd160(filename)
    Digest::RMD160.file(filename).hexdigest
  end
end
