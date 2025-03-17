import fs from 'fs';
import { globSync } from 'node:fs'
import path from 'path';
import getPort from 'get-port';
import { exec } from 'node:child_process';

//const { exec } = require('child_process');

export async function load({ url }) {
    // const probes = cookies.get('probes')
    const home = process.env.HOME.replaceAll('\\', '/');
    let wdir = url.searchParams.get('wdir'); 
    fs.existsSync(wdir) || (wdir = home);
    let ckt = url.searchParams.get('ckt');
    console.log(`wdir: ${wdir}`);
    console.log('home=', home);
    console.log('href = ', url.href);
    console.log('origin = ', url.origin);
    if (!wdir.endsWith('/')) wdir = wdir + '/';
    if (fs.existsSync(wdir)) {
        fs.readdir(wdir, (err, files) => {
            files.forEach(file => {
                // console.log(file);
            });
        });

        const files = globSync(wdir + '*.asc').concat(globSync(wdir + '*.sch')).concat(globSync(wdir + '*.edif'));
        const symbol_files = globSync(wdir + '*.asy').concat(globSync(wdir + '*.sym'))
        files.forEach(file => {
            // console.log(file);
        });
        const setting_files = globSync(wdir + '*_settings.json');
        console.log(setting_files);
        return {
            props: {
                home: home, port: await startGrape(), origin: url.origin,
                wdir: wdir, ckt: ckt, files: files.map(a => path.basename(a)), //, probes: probes
                symbol_files: symbol_files.map(a => path.basename(a)),
                setting_names: setting_files.map(a => path.basename(a).replace('_settings.json', ''))
            }
        };
    }
}

let current_dir = undefined;

async function startGrape() {
    if (current_dir == undefined) {
        current_dir = process.cwd();
    }
    let port = process.env.GRAPE;
    console.log('process.env.GRAPE', port);

    if (port != undefined) {
        return(port);
    }
    port = await getPort();
    console.log('port=', port);
    const command = `rackup -p ${port}`
    process.chdir(current_dir + '/Grape');
    console.log('command:', command, 'dir=', process.cwd());
    exec(command,  (error, stdout, stderr) => {
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
    return(port);
}
