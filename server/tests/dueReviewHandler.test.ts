import request from "supertest";
import server from "../server";
import { sequelize } from "../db/sequelize";
import { ReviewTask } from "../models/ReviewTask";
import jwt from "jsonwebtoken";

process.env.NODE_ENV = 'test';

let token: string;

describe("GET /api/reviews/due", () => {
  beforeAll(async () => {
    process.env.JWT_SECRET = 'test';

    token = jwt.sign({ username: "jerodahero" }, process.env.JWT_SECRET!, {
      algorithm: "HS256",
      expiresIn: "1h",
    });

    await sequelize.sync({ force: true });

    const today = new Date(new Date().toISOString().split("T")[0]);

    await ReviewTask.bulkCreate([
      {
        username: "jerodahero",
        problemId: "Graph Valid Tree",
        reviewDate: today,
        reviewed: false,
      },
      {
        username: "jerodahero",
        problemId: "Number of Connected Components in an Undirected Graph",
        reviewDate: today,
        reviewed: false,
      },
      {
        username: "jerodahero",
        problemId: "Some Other Problem",
        reviewDate: today,
        reviewed: true,
      }
    ]);
  });

  afterAll(async () => {
    await sequelize.close();
  });

  it("should return only return unreviewed tasks", async () => {
    const res = await request(server)
      .get("/api/reviews/due")
      .set("Authorization", `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(2);

    const problemIds = res.body.map((p: any) => p.problemId);
    expect(problemIds).toContain("Graph Valid Tree");
    expect(problemIds).toContain(
      "Number of Connected Components in an Undirected Graph"
    );

    expect(problemIds).not.toContain("Some Other Problem");
  });
});
