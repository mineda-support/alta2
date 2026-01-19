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
    if (!fs.existsSync(json_file)) {
        return json('');
    }
    const md_data = fs.readFileSync(json_file, {encoding: "utf8"});
    console.log('md_data=', md_data);
    return json(md_data);
}

export async function POST({ request, cookies }) {
    // console.log(request);
	const props = await request.json();
    const md_data = props.md_data;
    const md_file = props.md_file;
    const dir = path.dirname(md_file);
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    } 
    fs.writeFileSync(md_file, md_data
    );
    console.log('md_file=', md_file);
    console.log('md_data=', md_data);
    return json({status: 'success'}, { status: 201 });
}
