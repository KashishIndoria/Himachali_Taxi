const User = require('../models/user/User');

exports.getUserProfile = async (req, res) => {
  try {
    const user = await User.findById(req.query.id)
      .select('-password -otp')
      .lean();

    if (!user) {
      return res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }

    // Transform dates to ISO string format for frontend
    if (user.dateOfBirth) {
      user.dateOfBirth = user.dateOfBirth.toISOString();
    }
    if (user.createdAt) {
      user.createdAt = user.createdAt.toISOString();
    }
    if (user.updatedAt) {
      user.updatedAt = user.updatedAt.toISOString();
    }

    res.status(200).json({
      status: 'success',
      data: user
    });
  } catch (error) {
    console.error('Get user profile error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get user profile'
    });
  }
};

exports.updateUserProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const { firstName, phone, gender, dateOfBirth, address} = req.body;// Get user ID from auth middleware

    // Debug log
    console.log('Updating profile for user:', userId);
    console.log('Update data:', req.body);

    const updateData = {
      ...(firstName && { firstName }),
      ...(phone && { phone }),
      ...(gender && { gender }),
      ...(dateOfBirth && { dateOfBirth: new Date(dateOfBirth) }),
      ...(address && { address }),
    };

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      updateData,
      {
        new: true,
        runValidators: true,
        select: '-password -otp'
      }
    ).lean();

    if (!updatedUser) {
      console.log('User not found:', userId);
      return res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }

    // Transform dates
    if (updatedUser.dateOfBirth) {
      updatedUser.dateOfBirth = updatedUser.dateOfBirth.toISOString();
    }

    console.log('Profile updated successfully:', updatedUser);

    res.status(200).json({
      status: 'success',
      message: 'Profile updated successfully',
      data: updatedUser
    });
  } catch (error) {
    console.error('Profile update error:', error);
    res.status(500).json({
      status: 'error',
      message: error.message || 'Failed to update profile'
    });
  }
};

exports.updateUserProfileImage = async (req, res) => {
  try {
    const { profileImageUrl } = req.body;
    const userId = req.user.id;

    console.log('Updating profile image for user:', userId);
    console.log('New image URL:', profileImageUrl);

    if (!profileImageUrl) {
      return res.status(400).json({
        status: 'error',
        message: 'No image URL provided'
      });
    }

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      { profileImage: profileImageUrl },
      { new: true, select: '-password -otp' }
    ).lean();

    if (!updatedUser) {
      console.log('User not found:', userId);
      return res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }

    console.log('Profile image updated successfully:', updatedUser);

    res.status(200).json({
      status: 'success',
      message: 'Profile image updated successfully',
      data: {
        user: updatedUser,
        imageUrl: profileImageUrl
      }
    });
  } catch (error) {
    console.error('Profile image update error:', error);
    res.status(500).json({
      status: 'error',
      message: error.message || 'Failed to update profile image'
    });
  }
};

// exports.uploadProfileImage = async (req, res) => {
//   try {
//     if (!req.file) {
//       return res.status(400).json({
//         status: 'error',
//         message: 'No file uploaded'
//       });
//     }

//     console.log('Uploading profile image:', req.file);

//     const imageUrl = `/uploads/profiles/${req.file.filename}`;
//     const userId = req.user.id;
//     const updatedUser = await User.findByIdAndUpdate(
//       userId,
//       { profileImage: imageUrl },
//       { new: true, select: '-password -otp' }
//     ).lean();

//     if (!updatedUser) {
//       return res.status(404).json({
//           status: 'error',
//           message: 'User not found'
//       });
//   }

//   console.log('Profile image updated:', imageUrl); // Debug log

//     res.status(200).json({
//       status: 'success',
//       message: 'Profile image updated successfully',
//       data: {
//         imageUrl,
//         user: updatedUser
//       }
//     });
//   } catch (error) {
//     console.error('Upload error:', error);
//     res.status(500).json({
//       status: 'error',
//       message: error.message || 'Failed to upload profile image'
//     });
//   }
// };