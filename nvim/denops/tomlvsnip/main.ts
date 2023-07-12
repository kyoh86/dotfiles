import { Denops } from "https://deno.land/x/denops_std@v5.0.1/mod.ts";
import { execute } from "https://deno.land/x/denops_std@v5.0.1/helper/mod.ts";
import {
  ensure,
  isArrayOf,
  isNumber,
  isString,
} from "https://deno.land/x/unknownutil@v3.2.0/mod.ts";
import { expandGlob } from "https://deno.land/std@0.193.0/fs/mod.ts";
import { parse } from "https://deno.land/std@0.193.0/toml/parse.ts";
import { stringify } from "https://deno.land/std@0.193.0/toml/stringify.ts";
import { extname, join } from "https://deno.land/std@0.193.0/path/mod.ts";

function deconvertText(text: string) {
  const obj = JSON.parse(text);
  return stringify(obj);
}

export function main(denops: Denops): void {
  denops.dispatcher = {
    process: async (
      unknownPath: unknown,
      unknownDirs: unknown,
      unknownText: unknown,
      unknownIndent: unknown,
    ) => {
      const name = ensure(unknownPath, isString);
      const dirs = ensure(unknownDirs, isArrayOf(isString));
      const text = ensure(unknownText, isString);
      const indent = ensure(unknownIndent, isNumber);

      const ext = extname(name);
      const extTrim = name.substring(0, name.length - ext.length);
      const ft = (/\..+\./.test(name)) ? extTrim.replace(/^.+\./, "") : extTrim;
      const newPath = join(dirs[0], ft + ".json");
      const obj = parse(text);
      for (const dir of dirs) {
        const glob = `${dir}/*.${ft}.toml`;
        for await (const file of expandGlob(glob, { followSymlinks: true })) {
          if (!file.isFile) {
            continue;
          }
          if (file.path == name) {
            continue;
          }
          Object.assign(obj, parse(await Deno.readTextFile(file.path)));
        }
      }
      await Deno.writeTextFile(newPath, JSON.stringify(obj, null, indent));
      await execute(
        denops,
        `echomsg "Converted to ${newPath}"`,
      );
    },

    deconvert: async (unknownPath: unknown, unknownText: unknown) => {
      const name = ensure(unknownPath, isString);
      const text = ensure(unknownText, isString);

      const ext = extname(name);
      const newPath = name.substring(0, name.length - ext.length) + ".toml";
      await Deno.writeTextFile(newPath, deconvertText(text));
      await execute(
        denops,
        `echomsg "Deconverted to ${newPath}"`,
      );
    },
  };
}