/**
 * Ledgr Backend - Firebase Cloud Function / Cloud Run
 * Multimodal Gemini Parser for Indian Wholesale & Retail Bookkeeping
 */

const { GoogleGenerativeAI } = require("@google/generative-ai");

// Retrieve API key from environment
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || "";

const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);

const SYSTEM_INSTRUCTION = `
You are the AI bookkeeping engine for Ledgr, an accounting app for Indian traders and wholesalers.
Your job is to listen to voice notes (in Hindi, English, Hinglish, Gujarati, Marathi, Tamil) or inspect photos of handwritten bills,
and extract structured transaction details against the provided list of known parties and items.

CRITICAL RULES:
1. NEVER calculate GST amounts or totals. The app calculates all GST and totals in Dart code.
2. Match parties strictly using the provided parties list and their nicknames.
   - If spoken nickname matches (e.g. "Ramesh Bhai" -> "Ramesh Traders"), set matched_party_id to that party's ID.
   - If unsure or ambiguous, set matched_party_id to null and add a clarifying question to questions_for_user. NEVER guess!
3. Match items to known items. If not matched, set matched_item_id to null.
4. Detect if GST is included in the rate mentioned or added on top.
   - "GST lagao", "plus GST", "GST extra", "tax alag se" -> gst_included_in_rate: false
   - "GST ke saath", "inclusive", "with GST", "pakka rate" -> gst_included_in_rate: true
5. Output ONLY valid JSON matching the exact schema. No markdown formatting, no code fences, just raw JSON.

SCHEMA:
{
  "voucher_type": "sales|purchase|receipt|payment",
  "party_name_heard": string,
  "matched_party_id": string|null,
  "items": [
    {
      "name_heard": string,
      "matched_item_id": string|null,
      "quantity": number,
      "unit": string,
      "rate": number
    }
  ],
  "gst_included_in_rate": boolean,
  "notes": string,
  "confidence": number,
  "questions_for_user": [string]
}
`;

exports.parseVoucher = async (req, res) => {
  // Enable CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    return res.status(204).send("");
  }

  try {
    const { 
      audioBase64, 
      audioMimeType = "audio/mp3", 
      imageBase64, 
      imageMimeType = "image/jpeg", 
      textInput,
      partiesList = [], 
      itemsList = [] 
    } = req.body;

    const contextPrompt = `
KNOWN PARTIES:
${JSON.stringify(partiesList, null, 2)}

KNOWN ITEMS:
${JSON.stringify(itemsList, null, 2)}

Please parse the input transaction note.
`;

    // Step 1: Call Gemini Flash (primary)
    const flashModel = genAI.getGenerativeModel({
      model: "gemini-1.5-flash",
      systemInstruction: SYSTEM_INSTRUCTION,
      generationConfig: {
        responseMimeType: "application/json",
        temperature: 0.1,
      },
    });

    const parts = [{ text: contextPrompt }];

    if (audioBase64) {
      parts.push({
        inlineData: {
          mimeType: audioMimeType,
          data: audioBase64,
        },
      });
    } else if (imageBase64) {
      parts.push({
        inlineData: {
          mimeType: imageMimeType,
          data: imageBase64,
        },
      });
    } else if (textInput) {
      parts.push({ text: `Spoken / Transcribed text: "${textInput}"` });
    }

    let response = await flashModel.generateContent(parts);
    let resultText = response.response.text();
    let parsedResult = JSON.parse(resultText);

    // Step 2: Retry with Gemini Pro if confidence < 0.7
    if (parsedResult.confidence && parsedResult.confidence < 0.7) {
      console.log(`Flash confidence ${parsedResult.confidence} < 0.7. Retrying with Gemini Pro...`);
      const proModel = genAI.getGenerativeModel({
        model: "gemini-1.5-pro",
        systemInstruction: SYSTEM_INSTRUCTION,
        generationConfig: {
          responseMimeType: "application/json",
          temperature: 0.1,
        },
      });

      const proResponse = await proModel.generateContent(parts);
      resultText = proResponse.response.text();
      parsedResult = JSON.parse(resultText);
    }

    return res.status(200).json(parsedResult);
  } catch (error) {
    console.error("Gemini Parse Error:", error);
    return res.status(500).json({
      error: error.message || "Failed to process voucher via Gemini",
    });
  }
};
