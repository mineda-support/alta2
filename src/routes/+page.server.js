import fs from 'fs';
import { globSync } from 'node:fs'
import path from 'path';
import getPort from 'get-port';
import { exec } from 'node:child_process';

//const { exec } = require('child_process');
let current_dir = process.cwd();
const user = process.env.USER || process.env.USERNAME;

export async function load({ url, setHeaders }) {
    setHeaders({
        'cache-control': 'public, max-age=3600' 
    });
    // const probes = cookies.get('probes')
    const home = process.env.HOME.replaceAll('\\', '/');
    let command = url.searchParams.get('command');
    let wdir = url.searchParams.get('wdir');
    fs.existsSync(wdir) || (wdir = home);
    let ckt = url.searchParams.get('ckt');
    let settings_name = url.searchParams.get('settings_name');
    let gap = '';
    if (ckt) {
      gap = path.dirname(ckt);
      if (gap == '.') gap = '';
      ckt = path.basename(ckt);
      wdir = path.join(wdir, gap);
      console.log(`wdir: ${wdir} gap: ${gap} ckt: ${ckt}`);
    };
    console.log('home=', home);
    console.log('href = ', url.href);
    console.log('origin = ', url.origin);
    process.chdir(wdir);
    wdir = process.cwd();
    //if (!wdir.endsWith('/')) wdir = wdir + '/';
    if (fs.existsSync(wdir)) {
        fs.readdir(wdir, (err, files) => {
            files.forEach(file => {
                // console.log(file);
            });
        });
        const image_files = globSync(wdir + '/*.png');
        const targetDir = path.join(current_dir, 'static', user);
        fs.mkdir(targetDir, { recursive: true }, (err) => {
            if (err) throw err;
            console.log(`${targetDir} created`);
        });
        console.log("targetDir = ", targetDir);
        console.log("image_files = ", image_files);
        image_files.forEach(file => {
            const file_content = fs.readFileSync(file);
            fs.writeFileSync(path.join(targetDir, path.basename(file)), file_content);
        });
        const subdirs = globSync('*/');
        const files = globSync(wdir + '/*.asc').concat(globSync(wdir + '/*.sch'))
            .concat(globSync(wdir + '/*.edif'))
            .concat(globSync(wdir + '/*.out'));
        const symbol_files = globSync(wdir + '/*.asy').concat(globSync(wdir + '/*.sym'))
        const markdown_files = globSync(wdir + '/*.md').concat(globSync(wdir + '/*.markdoc'));
        files.forEach(file => {
            // console.log(file);
        });
        const setting_files = globSync(wdir + '*_settings.json');
        console.log(setting_files);
        const flow_files = globSync(wdir + '/FLOW/*.yaml');
        console.log("wdir=", wdir, "flow_files:", flow_files);
        return {
            props: { command: command, gap: gap, settings_name: settings_name,
                username: user, home: home, port: await startGrape(), origin: url.origin, show_flow: false,
                wdir: wdir, ckt: ckt, files: files.map(a => path.basename(a)), //, probes: probes
                symbol_files: symbol_files.map(a => path.basename(a)),
                sub_directories: subdirs.map(a => path.basename(a)),
                setting_names: setting_files.map(a => path.basename(a).replace('_settings.json', '')),
                flow_names: flow_files.map(a => path.basename(a).replace('.yaml', '')),
                markdown_files: markdown_files.map(a => path.basename(a))
            }
        };
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
