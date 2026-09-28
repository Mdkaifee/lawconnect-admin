import "dotenv/config";
import bcrypt from "bcryptjs";
import mongoose from "mongoose";
import { connectDB } from "./config/db.js";
import { Admin, Category, Case, Act, LegalUpdate, Post } from "./models/index.js";

async function run() {
  await connectDB();

  /* ---- Owner account: Rishikesh / Rishikesh@1 ---- */
  const username = process.env.ADMIN_USERNAME || "Rishikesh";
  const password = process.env.ADMIN_PASSWORD || "Rishikesh@1";
  const passwordHash = await bcrypt.hash(password, 10);
  await Admin.findOneAndUpdate(
    { username },
    { $set: { username, passwordHash, name: "Rishikesh Yadav", role: "owner" } },
    { upsert: true, new: true },
  );
  console.log(`Admin ready -> ${username}`);

  /* ---- Categories ---- */
  const cats = [
    { name: "Constitution", slug: "constitution", icon: "landmark", color: "#1e3a5f", order: 1 },
    { name: "Criminal Law", slug: "criminal-law", icon: "gavel", color: "#b8860b", order: 2 },
    { name: "Contract", slug: "contract", icon: "file-text", color: "#2e7d32", order: 3 },
    { name: "Torts", slug: "torts", icon: "scale", color: "#1565c0", order: 4 },
    { name: "Family Law", slug: "family-law", icon: "users", color: "#6a1b9a", order: 5 },
    { name: "Labour Law", slug: "labour-law", icon: "briefcase", color: "#c62828", order: 6 },
    { name: "Environment", slug: "environment", icon: "leaf", color: "#2e7d32", order: 7 },
  ];
  for (const c of cats) await Category.findOneAndUpdate({ slug: c.slug }, { $set: c }, { upsert: true });

  /* ---- Sample cases ---- */
  if ((await Case.countDocuments()) === 0) {
    await Case.insertMany([
      {
        title: "Kesavananda Bharati v. State of Kerala",
        citation: "(1973) 4 SCC 225",
        year: 1973,
        court: "Supreme Court of India",
        courtType: "Supreme Court",
        bench: "Chief Justice S.M. Sikri & Others",
        petitioners: "Kesavananda Bharati (And Others)",
        respondents: "State of Kerala (And Others)",
        dateOfJudgment: new Date("1973-04-24"),
        tags: ["Constitutional Law", "Basic Structure", "Article 368", "Amendment"],
        categories: ["constitution"],
        summary:
          "This landmark judgment laid down the doctrine of Basic Structure, holding that Parliament cannot amend the Constitution in a manner that destroys its basic structure.",
        simpleExplanation:
          "Parliament can change the Constitution, but it cannot change its core identity — things like democracy, judicial review and fundamental rights.",
        judgmentPdfUrl: "",
      },
      {
        title: "S.R. Bommai v. Union of India",
        citation: "(1994) 3 SCC 1",
        year: 1994,
        court: "Supreme Court of India",
        courtType: "Supreme Court",
        tags: ["Constitution", "Article 356", "Federalism"],
        categories: ["constitution"],
        summary: "Limited the arbitrary use of Article 356 and made Presidential proclamations subject to judicial review.",
      },
      {
        title: "Justice K.S. Puttaswamy v. Union of India (Right to Privacy)",
        citation: "(2017) 10 SCC 1",
        year: 2017,
        court: "Supreme Court of India",
        courtType: "Supreme Court",
        tags: ["Privacy", "Article 21", "Fundamental Rights"],
        categories: ["constitution"],
        summary: "Held that the right to privacy is a fundamental right under Article 21 of the Constitution.",
      },
    ]);
  }

  /* ---- Sample acts & sections ---- */
  if ((await Act.countDocuments()) === 0) {
    await Act.insertMany([
      {
        name: "Constitution of India",
        shortName: "Constitution",
        year: 1950,
        type: "Central",
        description: "English + Hindi",
        sections: [
          { number: "Article 21", title: "Protection of life and personal liberty", text: "No person shall be deprived of his life or personal liberty except according to procedure established by law." },
          { number: "Article 368", title: "Power of Parliament to amend the Constitution", text: "Parliament may, in exercise of its constituent power, amend by way of addition, variation or repeal any provision of this Constitution." },
        ],
      },
      { name: "Indian Penal Code (BNS)", shortName: "BNS", year: 2023, type: "Central", description: "Bharatiya Nyaya Sanhita, 2023", sections: [{ number: "Section 302", title: "Punishment for murder", text: "Whoever commits murder shall be punished with death or imprisonment for life, and shall also be liable to fine.", explanation: "Murder = intention + act + cause of death." }] },
      { name: "Code of Criminal Procedure (BNSS)", shortName: "BNSS", year: 2023, type: "Central", description: "Bharatiya Nagarik Suraksha Sanhita, 2023", sections: [] },
      { name: "Bharatiya Sakshya Adhiniyam", shortName: "BSA", year: 2023, type: "Central", description: "Law of evidence in India replacing the Indian Evidence Act, 1872", sections: [] },
      { name: "Indian Contract Act", shortName: "Contract Act", year: 1872, type: "Central", description: "Law of contracts", sections: [{ number: "Section 28", title: "Agreements in restraint of legal proceedings void", text: "Every agreement by which any party is restricted absolutely from enforcing his rights is void to that extent.", explanation: "Unconscionable contracts are void." }] },
      { name: "Indian Torts Act", shortName: "Torts", year: 1872, type: "Central", description: "Civil wrongs and remedies", sections: [] },
      { name: "Family Laws", shortName: "Family", type: "Central", description: "HMA, Muslim Law, Christian Law", sections: [] },
      { name: "Environment Laws", shortName: "Environment", type: "Central", description: "EP Act, Wildlife Act, etc.", sections: [] },
    ]);
  }

  /* ---- Sample legal updates ---- */
  if ((await LegalUpdate.countDocuments()) === 0) {
    await LegalUpdate.insertMany([
      { title: "SC seeks response from Centre on plea against Waqf (Amendment) Act, 2025", source: "LiveLaw", court: "Supreme Court", badge: "SC", publishedAt: new Date() },
      { title: "Delhi High Court upholds conviction in POCSO case", source: "Bar & Bench", court: "High Court", badge: "HC", publishedAt: new Date() },
      { title: "Centre notifies new rules under BNSS, 2023", source: "PIB", court: "Other", badge: "GOI", publishedAt: new Date() },
      { title: "NCLT admits insolvency plea against IRCTC", source: "The Hindu", court: "Other", badge: "NCLT", publishedAt: new Date() },
    ]);
  }

  /* ---- Sample posts ---- */
  if ((await Post.countDocuments()) === 0) {
    await Post.insertMany([
      {
        authorType: "admin", authorModel: "Admin", authorName: "Rishikesh Yadav", category: "Supreme Court",
        title: "SC grants interim relief on bail plea in PMLA case",
        content: "The Supreme Court has granted interim bail to the accused in a PMLA case, citing that prolonged incarceration without trial violates Article 21.",
        tags: ["SupremeCourt", "PMLA", "Bail"], likes: 45, commentsCount: 12,
      },
      {
        authorType: "admin", authorModel: "Admin", authorName: "Rishikesh Yadav", category: "Constitution",
        title: "Why is the Preamble important?",
        content: "The Preamble is not just an introduction, it is the soul of our Constitution. It sets the vision, values and goals of the nation.",
        tags: ["Constitution", "Preamble"], likes: 31, commentsCount: 7,
      },
    ]);
  }

  console.log("Seed complete.");
  await mongoose.disconnect();
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
