import { Denops } from "https://deno.land/x/denops_std@v5.0.1/mod.ts";
import { execute } from "https://deno.land/x/denops_std@v5.0.1/helper/mod.ts";
import {
  ensure,
  isNumber,
  isString,
} from "https://deno.land/x/unknownutil@v3.2.0/mod.ts";
import { parse } from "https://deno.land/std@0.193.0/toml/parse.ts";
import { stringify } from "https://deno.land/std@0.193.0/toml/stringify.ts";
import { extname } from "https://deno.land/std@0.193.0/path/mod.ts";

function convertText(text: string, indent: number) {
  const obj = parse(text);
  return JSON.stringify(obj, null, indent);
}

function reverseText(text: string) {
  const obj = JSON.parse(text);
  return stringify(obj);
}

function replaceName(unknownName: unknown, newExt: string) {
  const name = ensure(unknownName, isString);
  const ext = extname(name);
  return name.substring(0, name.length - ext.length) + "." + newExt;
}

export function main(denops: Denops): void {
  denops.dispatcher = {
    process: async (
      unknownName: unknown,
      unknownText: unknown,
      unknownIndent: unknown,
    ) => {
      const text = ensure(unknownText, isString);
      const indent = ensure(unknownIndent, isNumber);
      const newName = replaceName(unknownName, "json");
      await Deno.writeTextFile(newName, convertText(text, indent));
      await execute(
        denops,
        `echo "Converted to ${newName}"`,
      );
    },

    reverse: async (unknownName: unknown, unknownText: unknown) => {
      const text = ensure(unknownText, isString);
      const newName = replaceName(unknownName, "toml");
      await Deno.writeTextFile(newName, reverseText(text));
      await execute(
        denops,
        `echo "Reversed to ${newName}"`,
      );
    },
  };
}
