import fs from 'fs';
import { globSync } from 'node:fs'
import path from 'path';
import getPort from 'get-port';
import { exec } from 'node:child_process';

//const { exec } = require('child_process');
let current_dir = process.cwd();

export async function load({ url }) {
    // const probes = cookies.get('probes')
    const home = process.env.HOME.replaceAll('\\', '/');
    let wdir = url.searchParams.get('wdir'); 
    let show_flow = url.searchParams.get('show_flow');
    fs.existsSync(wdir) || (wdir = home);
    let ckt = url.searchParams.get('ckt');
    console.log(`wdir: ${wdir}`);
    console.log(`show_flow: ${show_flow}`)
    console.log('home=', home);
    console.log('href = ', url.href);
    console.log('origin = ', url.origin);
    process.chdir(wdir);
    wdir = process.cwd();
    if (!wdir.endsWith('/')) wdir = wdir + '/';
    if (fs.existsSync(wdir)) {
        fs.readdir(wdir, (err, files) => {
            files.forEach(file => {
                // console.log(file);
            });
        });
        const subdirs = globSync('*/');
        if (show_flow == 'true') {
            const files = globSync(wdir + '*.json');
            const json_files = globSync(wdir + 'json/*.json');
            const setting_files = globSync(wdir + '*_settings.json');
            const flow_files = globSync(wdir + '*_flow.json');
            console.log(setting_files);
            return {
                props: {
                    home: home, port: await startGrape(), origin: url.origin, show_flow: true,
                    wdir: wdir, ckt: ckt, 
                    files: files.map(a => path.basename(a)).concat(json_files.map(a => `json/${path.basename(a)}`)), //, probes: probes
                    symbol_files: [], sub_directories: subdirs.map(a => path.basename(a)),
                    setting_names: setting_files.map(a => path.basename(a).replace('_settings.json', '')),
                    flow_names: flow_files.map(a => path.basename(a).replace('_flow.json', ''))
                }
            };
        } else {
            const files = globSync(wdir + '*.asc').concat(globSync(wdir + '*.sch'))
                                                  .concat(globSync(wdir + '*.edif'))
                                                  .concat(globSync(wdir + '*.out'));
            const symbol_files = globSync(wdir + '*.asy').concat(globSync(wdir + '*.sym'))
            const markdown_files  = globSync(wdir + '*.md').concat(globSync(wdir + '*.markdoc'));
            files.forEach(file => {
                // console.log(file);
            });
            const setting_files = globSync(wdir + '*_settings.json');
            console.log(setting_files);
            const flow_files = globSync(wdir + '*_flow.json');
            return {
                props: {
                    home: home, port: await startGrape(), origin: url.origin, show_flow: false,
                    wdir: wdir, ckt: ckt, files: files.map(a => path.basename(a)), //, probes: probes
                    symbol_files: symbol_files.map(a => path.basename(a)),
                    sub_directories: subdirs.map(a => path.basename(a)),
                    setting_names: setting_files.map(a => path.basename(a).replace('_settings.json', '')),
                    flow_names: flow_files.map(a => path.basename(a).replace('_flow.json', '')),
                    markdown_files: markdown_files.map(a => path.basename(a))  
                }
            };
        }
    }
}

async function startGrape() {
    if (current_dir == undefined) {
        current_dir = process.cwd();
    }
    let port = process.env.GRAPE;
    console.log('process.env.GRAPE', port);

    if (port != undefined) {
        return (port);
    }
    port = await getPort();
    console.log('port=', port);
    const command = `rackup -p ${port}`
    process.chdir(current_dir + '/Grape');
    console.log('command:', command, 'dir=', process.cwd());
    exec(command, (error, stdout, stderr) => {
        if (error) {
            console.error(`error: ${error.message}`);
            return;
        }
        if (stderr) {
            console.error(`stderr: ${stderr}`);
            return;
        }
        console.log(`stdout:\n${stdout}`);
    });
    return (port);
}
