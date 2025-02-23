/**
 * A class to store lines with attributes.
 *
 * This class is used to store lines with attributes.
 */
export class AttributedLines {
  readonly #lines: string[] = [];
  readonly #attrs: (string | null)[] = [];

  push(line: string, attr: string | null = null) {
    this.#lines.push(line);
    this.#attrs.push(attr);
  }

  expand(lines: string[], attr: string | null = null) {
    this.#lines.push(...lines);
    this.#attrs.push(...lines.map(() => attr));
  }

  get lines() {
    return this.#lines;
  }

  get length() {
    return this.#lines.length;
  }

  get attrs() {
    return this.#attrs;
  }
}
