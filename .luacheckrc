max_comment_line_length = false

-- ignore global for testing
globals = { '_TEST' }

-- standard override for tests
files['spec/*_spec.lua'].std = '+busted'

-- standard override for rockspecs
files['rocks/'].std = '+rockspec'