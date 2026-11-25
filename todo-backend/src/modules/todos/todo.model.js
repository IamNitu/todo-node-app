const mongoose = require("mongoose");

const todoSchema = new mongoose.Schema(
  {
    ownerId: {
      type: String,
      required: true,
      index: true,
    },
    title: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      trim: true,
      default:""
    },
    completed: {
      type: Boolean,
      default: false,
    },
    dueAt: {
      type: Date,
      required: true,
    },
    priority: {
      type: String,
      enum: ["basic", "important", "urgent"],
      default: "basic",
    },
    reminderEnabled: {
      type: Boolean,
      default: false,
    },
  },
  { timestamps: true },
);

module.exports = mongoose.model("Todo", todoSchema);
