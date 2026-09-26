import bcrypt from "bcryptjs";
import { Admin, Category, Case, Act, LegalUpdate, Post } from "../models/index.js";

export async function autoSeed() {
  try {
    /* ---- Owner account: Rishikesh / Rishikesh@1 ---- */
    const username = process.env.ADMIN_USERNAME || "Rishikesh";
    const password = process.env.ADMIN_PASSWORD || "Rishikesh@1";
    const passwordHash = await bcrypt.hash(password, 10);
    await Admin.findOneAndUpdate(
      { username },
      { $set: { username, passwordHash, name: "Rishikesh Yadav", role: "owner" } },
      { upsert: true, new: true },
    );

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
    for (const c of cats) {
      await Category.findOneAndUpdate({ slug: c.slug }, { $set: c }, { upsert: true });
    }

    /* ---- Cases & Legal Updates (Synchronized via IndianKanoonService) ---- */
    if ((await Case.countDocuments()) < 10) {
      const { IndianKanoonService } = await import("../services/indianKanoon.js");
      await IndianKanoonService.syncToDatabase();
    }

    /* ---- Sample acts & sections if none exist ---- */
    if ((await Act.countDocuments()) === 0) {
      await Act.insertMany([
        {
          name: "Constitution of India",
          shortName: "Constitution",
          year: 1950,
          type: "Central",
          description: "The supreme law of India laying down the framework of political code, structure, and fundamental rights.",
          sections: [
            { number: "Article 14", title: "Equality before law", text: "The State shall not deny to any person equality before the law or the equal protection of the laws within the territory of India." },
            { number: "Article 19", title: "Protection of certain rights regarding freedom of speech, etc.", text: "All citizens shall have the right to freedom of speech and expression, assemble peacefully without arms, form associations, move freely throughout India." },
            { number: "Article 21", title: "Protection of life and personal liberty", text: "No person shall be deprived of his life or personal liberty except according to procedure established by law.", explanation: "Expanded by judiciary to include right to privacy, clean environment, speedy trial, and dignity." },
            { number: "Article 32", title: "Remedies for enforcement of rights conferred by this Part", text: "The right to move the Supreme Court by appropriate proceedings for the enforcement of the rights conferred by this Part is guaranteed." },
            { number: "Article 368", title: "Power of Parliament to amend the Constitution and procedure therefor", text: "Parliament may in exercise of its constituent power amend by way of addition, variation or repeal any provision of this Constitution in accordance with the procedure laid down in this article." },
          ],
        },
        {
          name: "Bharatiya Nyaya Sanhita (BNS), 2023",
          shortName: "BNS",
          year: 2023,
          type: "Central",
          description: "Substantive criminal law of India replacing the Indian Penal Code, 1860.",
          sections: [
            { number: "Section 103", title: "Punishment for murder", text: "Whoever commits murder shall be punished with death or imprisonment for life, and shall also be liable to fine." },
            { number: "Section 115", title: "Voluntarily causing hurt", text: "Whoever does any act with the intention of thereby causing hurt to any person, or with the knowledge that he is likely thereby to cause hurt, commits voluntarily causing hurt." },
          ],
        },
        {
          name: "Bharatiya Nagarik Suraksha Sanhita (BNSS), 2023",
          shortName: "BNSS",
          year: 2023,
          type: "Central",
          description: "Procedural criminal code replacing the Code of Criminal Procedure, 1973.",
          sections: [
            { number: "Section 35", title: "When police may arrest without warrant", text: "Any police officer may without an order from a Magistrate and without a warrant, arrest any person who commits in the presence of a police officer a cognizable offence." },
          ],
        },
        {
          name: "Indian Contract Act, 1872",
          shortName: "Contract Act",
          year: 1872,
          type: "Central",
          description: "Governs the law relating to contracts in India.",
          sections: [
            { number: "Section 10", title: "What agreements are contracts", text: "All agreements are contracts if they are made by the free consent of parties competent to contract, for a lawful consideration and with a lawful object." },
            { number: "Section 28", title: "Agreements in restraint of legal proceedings, void", text: "Every agreement by which any party thereto is restricted absolutely from enforcing his rights under or in respect of any contract is void to that extent." },
          ],
        },
      ]);
    }

    /* ---- Sample legal updates if none exist ---- */
    if ((await LegalUpdate.countDocuments()) === 0) {
      await LegalUpdate.insertMany([
        {
          title: "Supreme Court reserves verdict on constitutional validity of Citizenship Amendment Rules",
          source: "LiveLaw",
          court: "Supreme Court",
          badge: "SC",
          summary: "A 3-judge bench heard arguments regarding rules framed under the Citizenship (Amendment) Act.",
          sourceUrl: "https://www.livelaw.in",
          publishedAt: new Date(),
        },
        {
          title: "Delhi High Court clarifies interim relief parameters under Commercial Courts Act",
          source: "Bar & Bench",
          court: "High Court",
          badge: "HC",
          summary: "Court observed pre-institution mediation is mandatory unless urgent interim relief is explicitly demonstrated.",
          sourceUrl: "https://www.barandbench.com",
          publishedAt: new Date(),
        },
        {
          title: "Ministry of Law notifies digital signature rules for subordinate judiciary filings",
          source: "PIB Delhi",
          court: "Other",
          badge: "GOI",
          summary: "Standardized e-filing protocol rolled out for district courts across states.",
          sourceUrl: "https://pib.gov.in",
          publishedAt: new Date(),
        },
      ]);
    }

    /* ---- Sample posts if none exist ---- */
    if ((await Post.countDocuments()) === 0) {
      await Post.insertMany([
        {
          authorType: "admin",
          authorModel: "Admin",
          authorName: "Rishikesh Yadav",
          category: "Supreme Court",
          title: "Understanding the Doctrine of Proportionality in Administrative Actions",
          content: "The doctrine of proportionality requires that administrative actions or legislative measures should not be more drastic than necessary to achieve the desired result.",
          tags: ["AdministrativeLaw", "Constitution", "JudicialReview"],
          likes: 42,
          commentsCount: 8,
          status: "published",
        },
      ]);
    }

    console.log("AutoSeed: verification and database synchronization complete.");
  } catch (err) {
    console.error("AutoSeed Warning:", err?.message || err);
  }
}
