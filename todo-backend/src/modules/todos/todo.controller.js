const Todo = require("./todo.model");

const priorities = ["basic", "important", "urgent"];
const TITLE_MAX_LENGTH = 120;
const DESCRIPTION_MAX_LENGTH = 500;

const handleControllerError = (res, error, operation) => {
  console.error(`Todo ${operation} failed:`, error);

  if (error.name === "CastError" || error.name === "ValidationError") {
    return res.status(400).json({ error: "Todo data is invalid" });
  }

  return res.status(500).json({ error: "An unexpected server error occurred" });
};

const escapeRegex = (value)=>   value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

const getTodos = async (req, res)=>{
  try{
    const ownerId = req.get("x-device-id");

    if(!ownerId){
      return res.status(400).json({
        error:"x-device-id header is required",
      });
    }

    const rawSearch = req.query.search;

    if(rawSearch !== undefined && typeof rawSearch != "string"){
      return res.status(400).json({
        error:"Search must be text",
      });
    }

    const search = rawSearch?.trim() ||"";

    if (search.length > 120) {
      return res.status(400).json({
        error: "Search cannot exceed 120 characters",
      });
    }

    const filter = {ownerId};

    if(search){
      const safeSearch = escapeRegex(search);

      filter.$or=[
        {title:{$regex:safeSearch,$options:"i"}},
        {description:{$regex:safeSearch, $options:"i"}},
      ];
    }
    const todos = await Todo.find(filter).sort({
      dueAt: 1,
      createdAt: -1,
    });
    return res.status(200).json(todos);
  }
  catch(error){
    return handleControllerError(res, error, "list request");
  }
};

const createTodo = async (req, res) => {
  try {
    const ownerId = req.get("x-device-id");

    if (!ownerId) {
      return res.status(400).json({
        error: "x-device-id header is required",
      });
    }

    const { title, description, completed, dueAt, priority, reminderEnabled } = req.body;

    if (typeof title !== "string" || !title.trim()) {
      return res.status(400).json({ error: "Please provide a title" });
    }
    if (title.trim().length > TITLE_MAX_LENGTH) {
      return res.status(400).json({ error: "Title cannot exceed 120 characters" });
    }
    if (description !== undefined && typeof description !== "string") {
      return res.status(400).json({ error: "Description must be text" });
    }
    if (
      typeof description === "string" &&
      description.trim().length > DESCRIPTION_MAX_LENGTH
    ) {
      return res.status(400).json({
        error: "Description cannot exceed 500 characters",
      });
    }
    if (!dueAt || Number.isNaN(Date.parse(dueAt))) {
      return res.status(400).json({ error: "Please provide a valid due date and time" });
    }
    if (priority && !priorities.includes(priority)) {
      return res.status(400).json({ error: "Priority must be basic, important, or urgent" });
    }

    const todo = await Todo.create({
      ownerId,
      title: title.trim(),
      description: typeof description === "string" ? description.trim():"",
      completed: completed === true,
      dueAt: new Date(dueAt),
      priority: priority || "basic",
      reminderEnabled: reminderEnabled === true,
    });

    return res.status(201).json({ success: true, todo });
  } catch (error) {
    return handleControllerError(res, error, "create request");
  }
};

const updateTodo = async (req, res) => {
  try {
    const ownerId =req.get("x-device-id");

    if (!ownerId){
      return res.status(400).json({
        error:"x-device-id header is required"
      });
    }

    const updates = {};
    const { title, description, completed, dueAt, priority, reminderEnabled } = req.body;

    if (title !== undefined) {
      if (typeof title !== "string" || !title.trim()) {
        return res.status(400).json({ error: "Title cannot be empty" });
      }
      if (title.trim().length > TITLE_MAX_LENGTH) {
        return res.status(400).json({
          error: "Title cannot exceed 120 characters",
        });
      }
      updates.title = title.trim();
    }
    if(description !== undefined){
      if(typeof description !== "string"){
        return res.status(400).json({error:"Description must be text"});
      }
      if (description.trim().length > DESCRIPTION_MAX_LENGTH) {
        return res.status(400).json({
          error: "Description cannot exceed 500 characters",
        });
      }
      updates.description = description.trim();
    }
    if (completed !== undefined) {
      if (typeof completed !== "boolean") {
        return res.status(400).json({ error: "Completed must be true or false" });
      }
      updates.completed = completed;
    }
    if (dueAt !== undefined) {
      if (!dueAt || Number.isNaN(Date.parse(dueAt))) {
        return res.status(400).json({ error: "Please provide a valid due date and time" });
      }
      updates.dueAt = new Date(dueAt);
    }
    if (priority !== undefined) {
      if (!priorities.includes(priority)) {
        return res.status(400).json({ error: "Priority must be basic, important, or urgent" });
      }
      updates.priority = priority;
    }
    if (reminderEnabled !== undefined) {
      if (typeof reminderEnabled !== "boolean") {
        return res.status(400).json({ error: "Reminder enabled must be true or false" });
      }
      updates.reminderEnabled = reminderEnabled;
    }
    if (Object.keys(updates).length === 0) {
      return res.status(400).json({ error: "Provide at least one field to update" });
    }

    const todo = await Todo.findOneAndUpdate({_id:req.params.id, ownerId}, updates, {
      new: true,
      runValidators: true,
    });
    if (!todo) {
      return res.status(404).json({ error: "Todo not found" });
    }

    return res.status(200).json({ success: true, todo });
  } catch (error) {
    return handleControllerError(res, error, "update request");
  }
};

const deleteTodo = async (req, res) => {
  try {
    const ownerId =req.get("x-device-id");

    if(!ownerId){
      return res.status(400).json({
        error:"x-device-id header is required",
      });
    }
    const todo = await Todo.findOneAndDelete({_id:req.params.id, ownerId});
    if (!todo) {
      return res.status(404).json({ error: "Todo not found" });
    }
    return res.status(200).json({ success: true, todo });
  } catch (error) {
    return handleControllerError(res, error, "delete request");
  }
};

module.exports = { getTodos, createTodo, updateTodo, deleteTodo };
