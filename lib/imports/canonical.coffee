'use strict'

# canonical names: lowercase, strip whitespace from ends
export default canonical = (s) ->
  s = s.toLowerCase().replace(/^\s+/, '').replace(/\s+$/, '') # lower, strip
  return s
