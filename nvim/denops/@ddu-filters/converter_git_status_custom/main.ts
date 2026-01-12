import type { FilterArguments } from "@shougo/ddu-vim/filter";
import { BaseFilter } from "@shougo/ddu-vim/filter";
import type { DduItem, Item } from "@shougo/ddu-vim/types";

type ActionData = {
  status?: string;
};

type Params = {
  highlightAdded: string;
  highlightModified: string;
  highlightDeleted: string;
  highlightUntracked: string;
};

const defaultParams: Params = {
  highlightAdded: "DiffAdd",
  highlightModified: "DiffChange",
  highlightDeleted: "DiffDelete",
  highlightUntracked: "DiffText",
};

const NAME_ADDED = "ddu-git-status-custom:added";
const NAME_MODIFIED = "ddu-git-status-custom:modified";
const NAME_DELETED = "ddu-git-status-custom:deleted";
const NAME_UNTRACKED = "ddu-git-status-custom:untracked";

export class Filter extends BaseFilter<Params> {
  filter(args: FilterArguments<Params>): Promise<DduItem[]> {
    const {
      highlightAdded,
      highlightModified,
      highlightDeleted,
      highlightUntracked,
    } =
      args.filterParams;
    const highlightEnabled = highlightAdded !== "" ||
      highlightModified !== "" ||
      highlightDeleted !== "" ||
      highlightUntracked !== "";
    const items = args.items as Item<ActionData>[];
    for (const item of items) {
      const status = String(item.action?.status ?? "");
      if (!item.display?.startsWith(status)) {
        item.display = status + (item.display ?? item.word);
        if (item.highlights != null) {
          item.highlights = item.highlights.map((hl) => ({
            ...hl,
            col: hl.col + status.length,
          }));
        }
      }
      if (!highlightEnabled || status.length === 0) {
        continue;
      }
      const normalized = status.padEnd(2, " ");
      item.highlights ??= [];
      if (status.startsWith("??")) {
        if (highlightUntracked !== "") {
          item.highlights.push({
            name: NAME_UNTRACKED,
            hl_group: highlightUntracked,
            col: 1,
            width: 2,
          });
        }
        continue;
      }
      if (status.includes("U")) {
        if (highlightModified !== "") {
          item.highlights.push({
            name: NAME_MODIFIED,
            hl_group: highlightModified,
            col: 1,
            width: 2,
          });
        }
        continue;
      }
      if (normalized[0] === "D" || normalized[1] === "D") {
        if (highlightDeleted !== "") {
          const deletedCols = [];
          if (normalized[0] === "D") {
            deletedCols.push({ col: 1, width: 1 });
          }
          if (normalized[1] === "D") {
            deletedCols.push({ col: 2, width: 1 });
          }
          for (const hl of deletedCols) {
            item.highlights.push({
              name: NAME_DELETED,
              hl_group: highlightDeleted,
              col: hl.col,
              width: hl.width,
            });
          }
        }
        continue;
      }
      if (normalized[0] !== " " && highlightAdded !== "") {
        item.highlights.push({
          name: NAME_ADDED,
          hl_group: highlightAdded,
          col: 1,
          width: 1,
        });
      }
      if (normalized[1] !== " " && highlightModified !== "") {
        item.highlights.push({
          name: NAME_MODIFIED,
          hl_group: highlightModified,
          col: 2,
          width: 1,
        });
      }
    }
    return Promise.resolve(items as DduItem[]);
  }

  params(): Params {
    return defaultParams;
  }
}
