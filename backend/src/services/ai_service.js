import Groq from "groq-sdk";
import dotenv from "dotenv";

dotenv.config();

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY,
});

export const getAIInsights = async (data) => {
  try {
    const prompt = `
      You are an expert Logistics AI Analyst. Based on the following data, provide 3 actionable insights for the manager.
      Focus on Revenue, Fleet Health, and Efficiency.
      
      DATA:
      ${JSON.stringify(data)}
      
      FORMAT:
      Return a JSON array of 3 objects with keys "title" and "description".
    `;

    const chatCompletion = await groq.chat.completions.create({
      messages: [
        {
          role: "system",
          content: "You are a helpful logistics assistant. Always return valid JSON.",
        },
        {
          role: "user",
          content: prompt,
        },
      ],
      model: "llama-3.3-70b-versatile",
      response_format: { type: "json_object" },
    });

    return JSON.parse(chatCompletion.choices[0].message.content);
  } catch (error) {
    console.error("AI Insight Error:", error);
    return { insights: [] };
  }
};

export const predictShipmentDelay = async (shipmentData) => {
  try {
    const prompt = `
      Analyze this shipment and determine the probability of a delay (0-100%).
      Consider the status, priority, and progress.
      
      SHIPMENT:
      ${JSON.stringify(shipmentData)}
      
      RETURN:
      A JSON object with "probability" (number) and "reason" (string).
    `;

    const chatCompletion = await groq.chat.completions.create({
      messages: [
        { role: "user", content: prompt },
      ],
      model: "llama-3.3-70b-versatile",
      response_format: { type: "json_object" },
    });

    return JSON.parse(chatCompletion.choices[0].message.content);
  } catch (error) {
    console.error("AI Prediction Error:", error);
    return { probability: 0, reason: "Error computing prediction" };
  }
};
