import { Denops } from "jsr:@denops/std@~7.0.1";
import { execute } from "jsr:@denops/std@~7.0.1/helper";
import { ensure, is } from "jsr:@core/unknownutil@~4.0.0";
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
      const path = ensure(unknownPath, is.String);
      const name = ensure(unknownName, is.String);
      const dirs = ensure(unknownDirs, is.ArrayOf(is.String));
      const text = ensure(unknownText, is.String);
      const indent = ensure(unknownIndent, is.Number);

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
      const name = ensure(unknownPath, is.String);
      const text = ensure(unknownText, is.String);

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
