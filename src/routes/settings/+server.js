import fs from 'fs';
import glob from 'glob';
import path from 'path';
import { json } from '@sveltejs/kit';

export function GET({ url }) {
    const settings_name = url.searchParams.get('settings_name');
    const dir = url.searchParams.get('dir');
    const json_file = dir + settings_name + '_settings.json';
    console.log(json_file);
    const settings = JSON.parse(fs.readFileSync(json_file));
    return json(settings);
}

export async function POST({ request, cookies }) {
    // console.log(request);
	const props = await request.json();
    const wdir = props.wdir;
    const settings_name = props.settings_name;
    console.log(wdir);
    fs.writeFileSync(wdir+`${settings_name}_settings.json`, JSON.stringify(props));
    console.log(props);
    const setting_files = glob.sync(wdir + '*_settings.json');
	return json(setting_files.map(a => path.basename(a).replace('_settings.json', '')), { status: 201 });
}
