if defined? Clamby
  Clamby.configure({
    check: false,
    daemonize: true,
    output_level: 'medium',
    fdpass: true,
  })
end
