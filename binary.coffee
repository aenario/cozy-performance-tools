#!/usr/bin/env coffee
# `#!/usr/bin/env node
# `

program = require 'commander'
fs = require 'fs'
path = require 'path'
Promise = require 'bluebird'
{spawn, exec} = require 'child_process'
pexec = Promise.promisify exec
watcher = path.join(__dirname, '/main.coffee')
pidfile = path.join(__dirname, 'pidfile.pid')
pidOrder = ['couch', 'indexer', 'ds', 'proxy', 'home']
stream = null

program
    .option '-o, --output [filename] ', 'Output file names'
    .version require('./package.json').version

program.command 'start'
    .description 'Begin watching the stack'
    .action ->

        try running = fs.readFileSync pidfile
        if  running
            return console.log "ALREADY STARTED, RUN STOP"


        output = path.resolve program.output
        out = fs.openSync output + '.log', 'w'
        child = spawn __filename, ['watch', '--output', output],
            detached: true
            stdio: ['ignore', out, out]
        fs.writeFileSync pidfile, child.pid, encoding: 'ascii'
        console.log "STARTED PID=", child.pid
        child.unref()

program.command 'stop'
   .description 'Stop the watch'
   .action ->
        try running = fs.readFileSync pidfile
        unless  running
            return console.log "NO PID FOUND, KILL IT MANUALLY"

        exec 'kill ' + running, (err, stdout, stderr) ->
            console.log err, stderr if err
            fs.unlinkSync pidfile
            console.log "STOPPED", stdout

program.command 'plot'
    .description 'Plot the run'
    .action ->
        output = path.resolve program.output
        script = path.join __dirname, 'plotter.gp'
        pexec "gnuplot -e \"runname='#{output}'\" #{script} "
        .catch (err) -> console.log err

program.command 'watch'
    .description 'Watch the stack (kill to stop)'
    .action ->
        stream = fs.createWriteStream program.output + '.log.csv',
            encoding: 'utf8'

        headers = ['ellapsed']
            .concat pidOrder.map (x) -> x + '-rss'
            .concat pidOrder.map (x) -> x + '-cpu'

        stream.write headers.join(',') + "\n"
        tick null, Date.now(), stream
        .catch (err) -> console.log err

getPids = ->
    Promise.all [
        'ps h -C beam -o pid'
        'ps ax -o pid,command | grep [i]ndexer'
        'ps ax -o pid,command | grep [d]ata-system'
        'ps ax -o pid,command | grep [p]roxy'
        'ps ax -o pid,command | grep [c]ozy-home'
    ]

    .map (cmd) -> pexec(cmd).then parseInt
    .tap (newpids) -> pids = newpids

tick = (pids, start, stream) ->
    pPids = if pids then Promise.resolve pids
    else getPids()

    pStats = pPids.then (pids) ->
        stats = cpu: {}, rss: {}
        pexec 'top -b -n2 -p ' + pids.join(',')
        .then (out) -> out.toString().split("\n")[-2-(pids.length)..-3]
        .map (line) ->
            line = line.substring(1) if line[0] is ' '
            [pid, u, pr, ni, virt, rss, shr, s, cpu] = line.split /[ ]+/
            stats.rss[pid] = rss
            stats.cpu[pid] = parseFloat(cpu)
        .return stats


    Promise.join pPids, pStats, (pids, stats) ->
        values = [Date.now() - start]
        for pid in pids
            values.push stats.rss[pid]

        for pid in pids
            values.push stats.cpu[pid]

        stream.write values.join(',') + "\n"

    .delay 200
    .then -> tick pids, start, stream

if module.parent then exports = {getPids, tick}
else program.parse process.argv
