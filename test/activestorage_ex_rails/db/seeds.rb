require 'net/http'

10.times do
  user = User.new

  file_url = "http://robohash.org/#{SecureRandom.hex}.png"
  remote_file = Net::HTTP.get_response(URI.parse(file_url))
  user.avatar.attach(
    io: StringIO.new(remote_file.body), 
    filename: "#{SecureRandom.hex}.png", 
    content_type: 'image/png'
  )

  user.save
end
