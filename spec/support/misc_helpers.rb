def read_fixture_file(rel_path)
  filename = SPEC_PATH.join("fixture_files/", rel_path)
  File.read(filename).strip
end

def eq_time( expected_time )
  delta = 0.01.seconds
  be_within( delta ).of( expected_time )
end

