import fs from 'fs';
import { globSync } from 'node:fs'
import path from 'path';
import { json } from '@sveltejs/kit';

export function GET({ url }) {
    console.log('URL=', url);
    const md_file_name = url.searchParams.get('md_file_name');
    const dir = url.searchParams.get('dir');
    const json_file = dir + md_file_name;
    console.log('json_file=', json_file);
    const md_data = fs.readFileSync(json_file, {encoding: "utf8"});
    console.log('md_data=', md_data);
    return json(md_data);
}

export async function POST({ request, cookies }) {
    // console.log(request);
	const props = await request.json();
    const wdir = props.wdir;
    const settings_name = props.settings_name;
    console.log(wdir);
    fs.writeFileSync(wdir+`${settings_name}_settings.json`, JSON.stringify(props));
    console.log(props);
    const setting_files = globSync(wdir + '*_settings.json');
	return json(setting_files.map(a => path.basename(a).replace('_settings.json', '')), { status: 201 });
}
