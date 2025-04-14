export const handler = async (event: any) => {
  const body = JSON.parse(event.body || "{}");
  const { userId, problemId } = body;

  const intervals = [1, 3, 7, 14, 30];
  const now = new Date();
  console.log('test');
  const reviewSchedule = intervals.map((d) => {
    const reviewDate = new Date(now);
    reviewDate.setDate(now.getDate() + d);
    return reviewDate.toISOString().split("T")[0];
  });

  return {
    statusCode: 200,
    body: JSON.stringify({
      userId,
      problemId,
      solvedAt: now.toISOString(),
      reviewSchedule,
    }),
  };
};
