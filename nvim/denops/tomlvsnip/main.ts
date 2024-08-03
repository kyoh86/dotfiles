import { Denops } from "jsr:@denops/std@~7.0.1";
import { execute } from "jsr:@denops/std@~7.0.1/helper";
import {
  ensure,
  isArrayOf,
  isNumber,
  isString,
} from "jsr:@core/unknownutil@~3.18.1";
import { expandGlob } from "jsr:@std/fs@~1.0.1";
import { parse } from "jsr:@std/toml@~1.0.0";
import { stringify } from "jsr:@std/toml@~1.0.0";
import { extname, join } from "jsr:@std/path@~1.0.0";

function deconvertText(text: string) {
  const obj = JSON.parse(text);
  return stringify(obj);
}

export function main(denops: Denops): void {
  denops.dispatcher = {
    process: async (
      unknownPath: unknown,
      unknownName: unknown,
      unknownDirs: unknown,
      unknownText: unknown,
      unknownIndent: unknown,
    ) => {
      const path = ensure(unknownPath, isString);
      const name = ensure(unknownName, isString);
      const dirs = ensure(unknownDirs, isArrayOf(isString));
      const text = ensure(unknownText, isString);
      const indent = ensure(unknownIndent, isNumber);

      const ext = extname(path);
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
          if (file.path == path) {
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
