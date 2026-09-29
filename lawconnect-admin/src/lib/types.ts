export type LawCase = {
  _id: string;
  title: string;
  citation?: string;
  year?: number;
  court?: string;
  courtType?: string;
  bench?: string;
  petitioners?: string;
  respondents?: string;
  dateOfJudgment?: string;
  tags?: string[];
  categories?: string[];
  summary?: string;
  simpleExplanation?: string;
  fullText?: string;
  judgmentPdfUrl?: string;
  published?: boolean;
  createdAt?: string;
};

export type Section = {
  _id?: string;
  number: string;
  title?: string;
  text?: string;
  explanation?: string;
};

export type Act = {
  _id: string;
  name: string;
  shortName?: string;
  year?: number;
  type?: string;
  description?: string;
  sections: Section[];
  published?: boolean;
};

export type LegalUpdate = {
  _id: string;
  title: string;
  body?: string;
  source?: string;
  court?: string;
  badge?: string;
  url?: string;
  publishedAt?: string;
  published?: boolean;
};

export type Post = {
  _id: string;
  title: string;
  content: string;
  category?: string;
  authorName?: string;
  authorType?: string;
  tags?: string[];
  likes?: number;
  commentsCount?: number;
  status?: string;
  createdAt?: string;
};

export type AppUser = {
  _id: string;
  name: string;
  email: string;
  college?: string;
  headline?: string;
  photoUrl?: string;
  blocked?: boolean;
  createdAt?: string;
  isChatPaid?: boolean;
  chatPaidUntil?: string | null;
};

export type Stats = {
  counts: {
    cases: number;
    acts: number;
    posts: number;
    updates: number;
    users: number;
    notes: number;
    bookmarks: number;
  };
  recentCases: LawCase[];
  recentPosts: Post[];
};
