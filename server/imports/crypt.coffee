'use strict'

import crypto from 'crypto'
# fs = require 'fs'

# console.log("log from crypt.coffee");

# takes a string and a password string, returns an EJSON binary
export crypt = (data, password) ->
  password = new Buffer password, 'utf8' # encode string as utf8
  encrypt = crypto.createCipher 'aes256', password
  output1 = encrypt.update data, 'utf8', null
  output2 = encrypt.final null
  r = EJSON.newBinary(output1.length + output2.length);
  output1.copy r
  output2.copy r, output1.length
  r

# output = crypt("-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC5PGmkoEdqfhD5\nXyhfBxG868m+w1z7yzc4c5PnbVzD9ImJhNgvN3BcJS0dhCuGT9+ODkX3cG0gAWTa\nsNfjI0JkO7aRcaNo3aUJmTguodDwX3QSNILc5zvn1WGjoZcRSmIjtCkJmxije4ZC\ngAOvBx4MJHYqcMJ5jMqRKa4ysQVHw98JGNB44oGhOTwHeyXfeRqoPCEnAZ4qDaG+\ner6RuiHIvo0KD8HJ6Y7O55cWK+3FJbVBSRcouMhth+ItDazWUm8vBkXVRqDoiIXR\nuQCWqraPWjda+PbtLg+NoMwEQL7WTlspygClTq5KxadpftOK7CUqyPc2kA7LGHuP\nKShpgWmnAgMBAAECggEAWiVybDGsT8EmVZXfuc9g7IX7WqEM4WUWbJyiwB/S43Jg\ndNJ3uxLJ1a4p9JFb9TNt4l5D4pWOJeNHx74Ecn+4UbtVsBaTpfcn2DH+y4LogfKS\nNEHl5ceKudp4d/+t2zZN6H5G8mvOY9E7l6VhJY7bKqGb+C+EFU9VTavxIK5RmYh/\nD7OBqqtHVCO3lLE9k1zogepCfdq18jXLqSEvjnoL8PQoDgQwtg5nVC0kiySy3lGo\n58dCTOXnKBh+olRwNlGYPORehh6zINVmTFUM0lz1Z0Ka98MR0Ln/6LJO8I37TQFN\nq1IjFCD5lSSoPyGDHnrCdy68b19bTe8eRxsvQ2+JwQKBgQDkp9uj6Z2QHI5uybuy\nM7pqcqUeeqmiyoTCZ71i/2HaPA48cclRkLHzYv8tLNx9eWwH556yPIpr64sseH1Z\ntkPZFzXBBLwkjwLSH+dWygG/cnch8Xby+xuEoJ1YmqmXGUiVhjPHuKAVko0H4aub\n+3h5MjtYuigCa+mF7aFQrPapFwKBgQDPY0oJqJwUgLWwIi2O9NjfQSyTGkxcbFz7\n7A89TE7aWQt9H/yanjLkdXSqHyy/Zc62iYTQKBLo9P6xzDvM5ga7WTnx2AcpJltH\nxXDzHngBRdKUQuptvNdyIlcjkrYXQoguwAz26WggHHSN+Ff9qBgtWAs8/oDH5QgL\nflzI/qR98QKBgQCqE30Y98yeA8+h8mWtUDKpuOq+uAhzsOV84MMK3uB+/kqshQp0\npAbo/UrG5GaA4g8L9imhc8yWJ1aW1myOjTb8Q/pUvtve6Yz0lIxzjsAsEc0xLzUF\n2OeICBvhavEYFdNafL8JIHfac+543U/TLwJWS5m/DoByBKhnWPCzXGQAMwKBgCwT\n1UOSQ4IUDQmfagFtRr7Ekl29hCdMnMKqXF7R3hyIOmngp4aRQw3NbPtPXupbEAE5\n3zGCoupCT/OoDbmx1hJxl2AwYu07CsGJVEVH34eduHDse/jQ3xWR+OVFpE/zQxB0\nnwzHdOsGQTt/Yew2ktToVpMjIGnb4sbWl4/cl0dxAoGAfd1Xrd4bwNEuBXJH1VN3\nbN64acBsKdA+ftmldm01VH1nDvQvnWMc7a+N0cGAGmudiJNQva712QgUsyLNHSr5\nXCn69t2vvN9Jx2ewn87HSukLPfE1hKmQooleNuCzjxjLX++U2s7ux3yttAA7DfYM\n1r73RepbWymWu/+N+PSGpV0=\n-----END PRIVATE KEY-----\n", "");

# fs.writeFile "/Users/jennahimawan/Documents/wow/galackboard/private/drive-key.pem.crypt", output, (error) ->
#   console.error("Error writing file", error) if error


# takes an EJSON binary and a password string, returns a string.
export decrypt = (data, password) ->
  password = new Buffer password, 'utf8' # encode string as utf8
  decrypt = crypto.createDecipher 'aes256', password
  data = new Buffer data; # convert EJSON binary to Buffer
  output = decrypt.update data, null, 'utf8'
  output += decrypt.final 'utf8'
  output
