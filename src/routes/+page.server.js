import fs from 'fs';
import glob from 'glob';
import path from 'path';

/*
import { goto } from '$app/navigation';
export const actions = {
    default: async (event) => {
        console.log('form sent'); //alert('form sent');
        goto('/development/test3/');
    }
};    
*/
export function load({ url }) {
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

        const files = glob.sync(wdir + '*.asc').concat(glob.sync(wdir + '*.sch'));
        files.forEach(file => {
            // console.log(file);
        });
        const setting_files = glob.sync(wdir + '*_settings.json');
        console.log(setting_files);
        return {
            props: {
                home: home,
                wdir: wdir, ckt: ckt, files: files.map(a => path.basename(a)), //, probes: probes
                setting_names: setting_files.map(a => path.basename(a).replace('_settings.json', ''))
            }
        };
    }
}
