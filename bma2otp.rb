#!/usr/bin/ruby

# REQUIRES:
# * rooted android, as otherwise you can't read the applications private data
# * to display the qr code "qrencode" (http://fukuchi.org/works/qrencode/)
#   and "display" from ImageMagick

# This script "decrypts" the token from the internal state of the
# Battle.net Mobile Authenticator on android application, converting
# it into an "otpauth" url (https://code.google.com/p/google-authenticator/wiki/KeyUriFormat)
# and (using qrencode and display) displays it as QR code on the screen
# to scan it with any compatible app (FreeOTP for example; Google authenticator doesn't support digits=8)

# The decrypted token can either be read manually with root on the device (see below),
# or, if the device is attached and debug mode enabled, directly read by the script.

# Internals:
#
# The secret token (and serial) for the Battle.net Mobile Authenticator on android is stored
# in the file: /data/data/com.blizzard.bma/shared_prefs/com.blizzard.bma.AUTH_STORE.xml
# in the property "com.blizzard.bma.AUTH_STORE.HASH":
#
#   <?xml version='1.0' encoding='utf-8' standalone='yes' ?>
#   <map>
#   <long name="com.blizzard.bma.AUTH_STORE.CLOCK_OFFSET" value="[clock offset]" />
#   <int name="com.blizzard.bma.AUTH_STORE_HASH_VERSION" value="10" />
#   <string name="com.blizzard.bma.AUTH_STORE.HASH">["encrypted" token]</string>
#   <long name="com.blizzard.bma.AUTH_STORE.LAST_MODIFIED" value="[timestamp]" />
#   </map>

# The encrypted token is a hex string, encoding 57 bytes; decode it into a byte array, decrypt it with
# the xor "mask". The decrypted token now consists of 40 bytes hex-encoding the secret and 17 bytes with
# the serial (US|EU)-\d{4}-\d{4}-\d{4}

# The hex-decoded secret can be used with TOTP (RFC 6238; X = 30, T0 = 0, digit = 8) to generate
# the authentication codes.

def base32(str)
	cDIGITS = ('A'..'Z').to_a + ('2'..'7').to_a
	dMASK = 0x1f
	cSHIFT = 5

	bytes = str.unpack('C*')

	paddedLen = 8 * ((bytes.length + 4)/5)

	bits = 0
	haveBits = 0

	b32 = []
	bytes.each do |byte|
		bits = (bits << 8) | byte
		haveBits += 8

		while haveBits >= cSHIFT
			b32 << cDIGITS[dMASK & (bits >> (haveBits - cSHIFT))]
			haveBits -= cSHIFT
		end
		bits &= dMASK
	end

	if haveBits > 0
		b32 << cDIGITS[dMASK & (bits << (cSHIFT - haveBits))]
	end

	b32.join + "=" * (paddedLen - b32.length)
end

def otpauth(serial, token)
	"otpauth://totp/#{serial}:#{serial}?secret=#{base32(token)}&issuer=#{serial}&digits=8"
end

mask = [57,142,39,252,80,39,106,101,96,101,176,229,37,244,192,108,4,198,16,117,40,107,142,122,237,165,157,169,129,59,93,214,200,13,47,179,128,104,119,63,165,155,164,124,23,202,108,100,121,1,92,29,91,139,143,107,154]

STDOUT.puts "Enter encrypted token (or press enter to read with adb shell): "

token = STDIN.readline.strip

if token.length == 0
	IO.popen(["adb", "shell", "cat", "/data/data/com.blizzard.bma/shared_prefs/com.blizzard.bma.AUTH_STORE.xml"], "r") do |i|
		i.readlines.each do |line|
			m = /<string name="com.blizzard.bma.AUTH_STORE.HASH">(.*)<\/string>/.match(line)
			token = m[1] if m
		end
	end
end

token = [token].pack('H*').unpack('C*').zip(mask).map { |a,b| a ^ b }.pack('C*')

serial = token[40..-1]
token = [token[0..39]].pack('H*')

otpurl = otpauth(serial, token)
puts otpurl

require 'tempfile'

img = Tempfile.new(['otpauth_qr', '.png'])
if system("qrencode", "-s", "5", "-o", img.path, otpurl)
	puts "press escape to exit 'display'"
	STDERR.puts "'display' failed, maybe binary is not available" if not system("display", img.path)
else
	STDERR.puts "'qrencode' failed, maybe binary is not available?"
end
