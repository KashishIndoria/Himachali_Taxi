const multer = require('multer');
const path = require('path');
const { VIDEO_UPLOAD_PATH, ALLOWED_VIDEO_TYPES, MAX_VIDEO_SIZE } = require('../config/video.config');

// Configure storage
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, VIDEO_UPLOAD_PATH);
    },
    filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
    }
});

// File filter
const fileFilter = (req, file, cb) => {
    if (ALLOWED_VIDEO_TYPES.includes(file.mimetype)) {
        cb(null, true);
    } else {
        cb(new Error('Invalid file type. Only video files are allowed.'), false);
    }
};

// Configure upload
const upload = multer({
    storage: storage,
    fileFilter: fileFilter,
    limits: {
        fileSize: MAX_VIDEO_SIZE
    }
});

module.exports = upload; 