import OpenAI from "openai";

let client = null;
if (process.env.OPENAI_API_KEY) {
  client = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY
  });
} else {
  console.log("OpenAI API key not configured. AI features will be disabled.");
}

export default client;
