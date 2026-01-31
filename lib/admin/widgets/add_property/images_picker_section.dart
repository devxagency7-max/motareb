import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:admin_motareb/utils/custom_snackbar.dart';
import 'package:admin_motareb/services/r2_upload_service.dart';
import 'package:admin_motareb/core/utils/loc_extension.dart';
import 'add_property_helpers.dart';

class ImagesPickerSection extends StatefulWidget {
  final ValueNotifier<List<String>> imagesNotifier;
  final ValueNotifier<String?> videoNotifier;
  final ImagePicker picker;
  final TextEditingController adminNumberController;
  final ValueNotifier<String?> idErrorNotifier;

  const ImagesPickerSection({
    super.key,
    required this.imagesNotifier,
    required this.videoNotifier,
    required this.picker,
    required this.adminNumberController,
    required this.idErrorNotifier,
  });

  @override
  State<ImagesPickerSection> createState() => _ImagesPickerSectionState();
}

class _ImagesPickerSectionState extends State<ImagesPickerSection> {
  final R2UploadService _uploadService = R2UploadService();
  final Map<String, double> _uploadProgress =
      {}; // File path -> progress (0.0 to 1.0)

  Future<void> _processUploads(List<File> files) async {
    final number = widget.adminNumberController.text.trim();
    if (number.isEmpty) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: context.loc.enterPropertyIdFirst,
          isError: true,
        );
      }
      return;
    }
    if (widget.idErrorNotifier.value != null) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: context.loc.cannotUploadDuplicateId,
          isError: true,
        );
      }
      return;
    }

    final formattedId = 'T${number}Z';

    for (final file in files) {
      if (!mounted) return;

      setState(() {
        _uploadProgress[file.path] = 0.1;
      });

      try {
        final url = await _uploadService.uploadFile(
          file,
          propertyId: formattedId,
          onProgress: (sent, total) {
            if (mounted) {
              setState(() {
                _uploadProgress[file.path] = sent / total;
              });
            }
          },
        );

        if (mounted) {
          final currentUrls = List<String>.from(widget.imagesNotifier.value);
          currentUrls.add(url);
          widget.imagesNotifier.value = currentUrls;

          setState(() {
            _uploadProgress.remove(file.path);
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _uploadProgress.remove(file.path);
          });
          CustomSnackBar.show(
            context: context,
            message: 'فشل رفع صورة: $e',
            isError: true,
          );
        }
      }
    }
  }

  Future<void> _pickMultiImages(BuildContext context) async {
    try {
      final List<XFile> images = await widget.picker.pickMultiImage();
      if (images.isNotEmpty) {
        final files = images.map((x) => File(x.path)).toList();
        await _processUploads(files);
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'فشل اختيار الصور: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _pickVideo(BuildContext context) async {
    final number = widget.adminNumberController.text.trim();
    if (number.isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: context.loc.enterPropertyIdFirst,
        isError: true,
      );
      return;
    }
    if (widget.idErrorNotifier.value != null) {
      CustomSnackBar.show(
        context: context,
        message: context.loc.cannotUploadDuplicateId,
        isError: true,
      );
      return;
    }

    final formattedId = 'T${number}Z';

    try {
      final XFile? video = await widget.picker.pickVideo(
        source: ImageSource.gallery,
      );
      if (video != null) {
        final file = File(video.path);

        setState(() {
          _uploadProgress[file.path] = 0.1;
        });

        try {
          final url = await _uploadService.uploadFile(
            file,
            propertyId: formattedId,
            onProgress: (sent, total) {
              if (mounted) {
                setState(() {
                  _uploadProgress[file.path] = sent / total;
                });
              }
            },
          );
          if (mounted) {
            widget.videoNotifier.value = url;
            setState(() {
              _uploadProgress.remove(file.path);
            });
            CustomSnackBar.show(
              context: context,
              message: context.loc.videoUploadedSuccess,
              isError: false,
            );
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _uploadProgress.remove(file.path);
            });
            CustomSnackBar.show(
              context: context,
              message: 'فشل رفع الفيديو: $e',
              isError: true,
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'خطأ في اختيار الفيديو: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _deleteVideo(BuildContext context, String url) async {
    setState(() {
      _uploadProgress['deleting_video'] = 0.5;
    });

    try {
      await _uploadService.deleteFile(url);
      if (mounted) {
        widget.videoNotifier.value = null;
        CustomSnackBar.show(
          context: context,
          message: context.loc.videoDeleteSuccess,
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'فشل حذف الفيديو: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadProgress.remove('deleting_video');
        });
      }
    }
  }

  Future<void> _deleteImage(BuildContext context, String url) async {
    try {
      await _uploadService.deleteFile(url);

      if (mounted) {
        final updated = List<String>.from(widget.imagesNotifier.value);
        updated.remove(url);
        widget.imagesNotifier.value = updated;

        CustomSnackBar.show(
          context: context,
          message: context.loc.imageDeleteSuccess,
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'فشل حذف الصورة: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(context.loc.propertyImages),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: ValueListenableBuilder<List<String>>(
            valueListenable: widget.imagesNotifier,
            builder: (context, imageUrls, child) {
              final isUploading = _uploadProgress.isNotEmpty;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: imageUrls.length + 1 + (isUploading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return GestureDetector(
                      onTap: isUploading
                          ? null
                          : () => _pickMultiImages(context),
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(left: 10),
                        decoration: BoxDecoration(
                          color: isUploading ? Colors.grey.shade200 : null,
                          gradient: isUploading
                              ? null
                              : LinearGradient(
                                  colors: [
                                    const Color(0xFF39BB5E).withOpacity(0.1),
                                    const Color(0xFF008695).withOpacity(0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isUploading
                                ? Colors.grey
                                : const Color(0xFF39BB5E),
                            style: BorderStyle.solid,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isUploading)
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else ...[
                              const Icon(
                                Icons.add_photo_alternate_rounded,
                                color: Color(0xFF39BB5E),
                                size: 35,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                context.loc.addPhotos,
                                style: GoogleFonts.cairo(
                                  color: const Color(0xFF39BB5E),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }

                  if (isUploading && index == 1) {
                    return Container(
                      width: 120,
                      margin: const EdgeInsets.only(left: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.blueAccent.withOpacity(0.5),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${_uploadProgress.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              context.loc.uploading,
                              style: const TextStyle(fontSize: 10),
                            ),
                            const SizedBox(height: 5),
                            const CircularProgressIndicator(strokeWidth: 2),
                          ],
                        ),
                      ),
                    );
                  }

                  final urlIndex = index - 1 - (isUploading ? 1 : 0);
                  if (urlIndex < 0 || urlIndex >= imageUrls.length)
                    return const SizedBox();

                  final url = imageUrls[urlIndex];

                  return Stack(
                    children: [
                      Container(
                        width: 120,
                        margin: const EdgeInsets.only(left: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                            image: NetworkImage(url),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: GestureDetector(
                          onTap: () => _deleteImage(context, url),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        SectionLabel(context.loc.propertyVideoOptional),
        const SizedBox(height: 10),
        ValueListenableBuilder<String?>(
          valueListenable: widget.videoNotifier,
          builder: (context, videoUrl, child) {
            final isUploadingVideo = _uploadProgress.keys.any(
              (k) => k.endsWith('.mp4') || k.endsWith('.mov'),
            );
            final isDeleting = _uploadProgress.containsKey('deleting_video');

            if (videoUrl != null) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.loc.videoUploadedSuccess,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isDeleting)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteVideo(context, videoUrl),
                      ),
                  ],
                ),
              );
            }

            if (isUploadingVideo) {
              final activeUploadPath = _uploadProgress.keys.firstWhere(
                (k) => k.endsWith('.mp4') || k.endsWith('.mov'),
                orElse: () => '',
              );
              final progress = _uploadProgress[activeUploadPath] ?? 0.0;
              final percentage = (progress * 100).toStringAsFixed(0);

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.loc.uploadingVideo,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$percentage%',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.blue.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue.shade700,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ],
                ),
              );
            }

            return GestureDetector(
              onTap: (isDeleting) ? null : () => _pickVideo(context),
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        context.loc.clickToUploadVideo,
                        style: GoogleFonts.cairo(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
