import fs from 'fs';
import { globSync } from 'node:fs'
import path from 'path';
import getPort from 'get-port';
import { exec } from 'node:child_process';
//const { exec } = require('child_process');

/*
import { goto } from '$app/navigation';
export const actions = {
    default: async (event) => {
        console.log('form sent'); //alert('form sent');
        goto('/development/test3/');
    }
};    
*/
export async function load({ url }) {
    // const probes = cookies.get('probes')
    const home = process.env.HOME.replaceAll('\\', '/');
    let wdir = url.searchParams.get('wdir') || home + '/Seafile/PTS06_2022_8/BGR_TEG/';
    let ckt = url.searchParams.get('ckt');
    console.log(`wdir: ${wdir}`);
    if (!wdir.endsWith('/')) wdir = wdir + '/';
    if (fs.existsSync(wdir)) {
        fs.readdir(wdir, (err, files) => {
            files.forEach(file => {
                // console.log(file);
            });
        });

        const files = globSync(wdir + '*.asc').concat(globSync(wdir + '*.sch'));
        files.forEach(file => {
            // console.log(file);
        });
        const setting_files = globSync(wdir + '*_settings.json');
        console.log(setting_files);
        return {
            props: {
                home: home, port: await startGrape(),
                wdir: wdir, ckt: ckt, files: files.map(a => path.basename(a)), //, probes: probes
                setting_names: setting_files.map(a => path.basename(a).replace('_settings.json', ''))
            }
        };
    }
}

async function startGrape() {
    const port = await getPort();
    console.log('port=', port);
    const command = `rackup -p ${port}`
    process.chdir('Grape');
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
