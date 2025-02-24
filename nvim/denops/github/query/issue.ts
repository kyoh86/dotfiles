import { ensure, is } from "jsr:@core/unknownutil@4.3";
import type { Client } from "../client.ts";

export interface Root {
  data: Data;
}

export interface Data {
  repository: Repository;
}

export interface Repository {
  issue: Issue;
}

export interface Issue {
  number: number;
  title: string;
  body: string;
  state: string;
  createdAt: string;
  updatedAt: string;
  closedAt: string | null;
  labels: Label[];
  assignees: UserLogin[];
  milestone: Milestone | null;
  author: UserLogin;
  url: string;
  comments: Comment[];
}

export interface Milestone {
  title: string;
}

export interface Label {
  name: string;
}

export interface UserLogin {
  login: string;
}

export interface Comment {
  authorAssociation: string;
  body: string;
  databaseId: number;
  createdAt: string;
  updatedAt: string;
  author: UserLogin;
  isMinimized: boolean;
  minimizedReason: string | null;
}

export interface PageInfo {
  endCursor: string;
  hasNextPage: boolean;
}

export async function query(
  client: Client,
  owner: string,
  repo: string,
  issue_number: number,
): Promise<Issue> {
  const { repository } = ensure(
    await client.graphql.paginate(`query paginate($cursor: String) {
      repository(owner: "${owner}", name: "${repo}") {
        issue(number: ${issue_number}) {
          number
          title
          body
          state
          createdAt
          updatedAt
          closedAt
          labels(first: 100) {
            nodes {
              name
            }
          }
          assignees(first: 100) {
            nodes {
              login
            }
          }
          milestone {
            title
          }
          author {
            login
          }
          url
          comments(first: 100, after: $cursor) {
            nodes {
              databaseId
              authorAssociation
              body
              createdAt
              updatedAt
              author {
                login
              }
              isMinimized
              minimizedReason
            }
            pageInfo {
              endCursor
              hasNextPage
            }
          }
        }
      }
    }`),
    is.ObjectOf({
      repository: is.Unknown,
    }),
  );
  const { issue } = ensure(
    repository,
    is.ObjectOf({
      issue: is.Unknown,
    }),
  );
  const {
    number,
    title,
    body,
    state,
    createdAt,
    updatedAt,
    closedAt,
    labels,
    assignees,
    milestone,
    author,
    url,
    comments: uComments,
  } = ensure(
    issue,
    is.ObjectOf({
      number: is.Number,
      title: is.String,
      body: is.String,
      state: is.String,
      createdAt: is.String,
      updatedAt: is.String,
      closedAt: is.UnionOf([is.String, is.Null]),
      labels: is.ObjectOf({
        nodes: is.ArrayOf(is.ObjectOf({ name: is.String })),
      }),
      assignees: is.ObjectOf({
        nodes: is.ArrayOf(is.ObjectOf({ login: is.String })),
      }),
      milestone: is.UnionOf([is.Null, is.ObjectOf({ title: is.String })]),
      author: is.ObjectOf({ login: is.String }),
      url: is.String,
      comments: is.ObjectOf({
        nodes: is.ArrayOf(is.Unknown),
        pageInfo: is.ObjectOf({
          endCursor: is.UnionOf([is.Null, is.String]),
          hasNextPage: is.Boolean,
        }),
      }),
    }),
  );

  const comments = uComments.nodes.map((uComment) =>
    ensure(
      uComment,
      is.ObjectOf({
        authorAssociation: is.String,
        body: is.String,
        databaseId: is.Number,
        createdAt: is.String,
        updatedAt: is.String,
        author: is.ObjectOf({ login: is.String }),
        isMinimized: is.Boolean,
        minimizedReason: is.UnionOf([is.Null, is.String]),
      }),
    )
  );

  return {
    number,
    title,
    body,
    state,
    createdAt,
    updatedAt,
    closedAt,
    labels: labels.nodes,
    assignees: assignees.nodes,
    milestone,
    author,
    url,
    comments,
  };
}
