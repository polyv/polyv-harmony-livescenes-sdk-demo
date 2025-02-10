import {
  PLVCommonConstants,
  PLVLiveSceneSDK,
  PLVLogger,
  PLVSimpleWeb,
  PLVWebController,
  PLVToastUtils,
  PLVUtils
} from '@polyvharmony/live-scenes-sdk';
import { lateInit, runCatching } from '@polyvharmony/media-player-sdk';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { image } from '@kit.ImageKit';
import fs from '@ohos.file.fs'
import { display } from '@kit.ArkUI';

const TAG = 'PLVSAMoreShareLayout'

@CustomDialog
export struct PLVSAMoreShareLayout {
  controller: CustomDialogController = lateInit()

  build() {
    if (this.isPortrait()) {
      PLVSAMoreShareLayoutPort({
        controller: this.controller
      })
    } else {
      PLVSAMoreShareLayoutLand({
        controller: this.controller
      })
    }
  }

  private isPortrait(): boolean {
    const orientation = display.getDefaultDisplaySync().orientation
    return orientation === display.Orientation.PORTRAIT || orientation === display.Orientation.PORTRAIT_INVERTED
  }
}

// <editor-fold defaultstate="collapsed" desc="竖屏">

@Component
struct PLVSAMoreShareLayoutPort {
  controller: CustomDialogController = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  private readonly webController = new PLVWebController()
  @State private posterUrl: string = ""
  private saveImageController: CustomDialogController | undefined = undefined
  private readonly plvsa_more_share_poster_web = 'plvsa_more_share_poster_web'

  async aboutToAppear(): Promise<void> {
    const posterUrl = await runCatching(this.sdk.interactManager.invitePoster.getInvitePosterUrl())
    if (posterUrl.success === true) {
      this.posterUrl = posterUrl.data
      this.webController.loadUrlCatch(this.posterUrl)
    } else {
      PLVLogger.error(TAG, `load invite poster fail: ${posterUrl.error.message}`)
    }
  }

  build() {
    RelativeContainer() {
      Stack() {
        Stack() {
          PLVSimpleWeb({
            controller: this.webController,
            src: this.posterUrl
          })
            .id(this.plvsa_more_share_poster_web)
        }
        .aspectRatio(9 / 16)
        .borderRadius(8)
        .clip(true)
      }
      .id('plvsa_more_share_poster_container')
      .width('100%')
      .margin({
        top: 4,
        bottom: 24
      })
      .alignRules({
        top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
        bottom: { anchor: 'plvsa_more_share_action_layout', align: VerticalAlign.Top }
      })

      Column() {
        Grid() {
          GridItem() {
            ShareActionButton({
              image: $r('app.media.plvsa_more_share_action_save_image_icon'),
              name: $r('app.string.plvsa_more_share_action_save_image')
            })
              .onClick(() => this.onClickSaveImage())
          }

          GridItem() {
            ShareActionButton({
              image: $r('app.media.plvsa_more_share_action_copy_link_icon'),
              name: $r('app.string.plvsa_more_share_action_copy_link')
            })
              .onClick(() => this.onClickCopyLink())
          }
        }
        .layoutWeight(1)
        .columnsTemplate('1fr 1fr')

        Button($r('app.string.plvsa_more_share_action_cancel'))
          .width(240)
          .height(40)
          .margin({
            top: 18
          })
          .fontColor('#ffffff')
          .fontSize(14)
          .backgroundColor('#19ffffff')
          .borderRadius(30)
          .onClick(() => {
            this.controller.close()
          })
      }
      .id('plvsa_more_share_action_layout')
      .width('100%')
      .height(200)
      .padding({
        left: 25,
        right: 25,
        top: 28,
        bottom: 28
      })
      .backgroundColor('#2C2C2C')
      .borderRadius({
        topLeft: 16,
        topRight: 16
      })
      .alignRules({
        bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#80464646')
  }

  private async onClickSaveImage() {
    const pixelMapResult = await runCatching(this.getUIContext()
      .getComponentSnapshot()
      .get(this.plvsa_more_share_poster_web))
    if (pixelMapResult.success === false) {
      PLVLogger.error(TAG, `saveImage failed: ${pixelMapResult.error.message}`)
      PLVToastUtils.shortShow($r('app.string.plvsa_more_share_action_save_image_fail_toast'))
      return
    }
    this.saveImageController = new CustomDialogController({
      builder: SaveImageDialogPort({
        pixelMap: pixelMapResult.data
      }),
      customStyle: true
    })
    this.saveImageController.open()
  }

  private async onClickCopyLink() {
    const watchUrlResult = await runCatching(this.sdk.interactManager.invitePoster.getLiveWatchUrl())
    if (watchUrlResult.success === true) {
      const watchUrl = watchUrlResult.data
      await PLVUtils.copyText(watchUrl)
      PLVToastUtils.shortShow($r('app.string.plvsa_chat_copy_success'))
    }
  }
}

@CustomDialog
struct SaveImageDialogPort {
  controller?: CustomDialogController = lateInit()
  pixelMap: PixelMap = lateInit()

  build() {
    Column() {
      Image(this.pixelMap)
        .margin({
          bottom: 20
        })
        .aspectRatio(9 / 16)
        .objectFit(ImageFit.Contain)

      SaveButton({
        icon: SaveIconStyle.FULL_FILLED,
        text: SaveDescription.SAVE_IMAGE
      })
        .onClick(async () => {
          const result = await runCatching(this.saveImage())
          if (result.success === true) {
            PLVToastUtils.shortShow($r('app.string.plvsa_more_share_action_save_image_success_toast'))
            this.controller?.close()
          } else {
            PLVLogger.error(TAG, `saveImage failed: ${result.error.message}`)
            PLVToastUtils.shortShow($r('app.string.plvsa_more_share_action_save_image_fail_toast'))
          }
        })
    }
    .width(260)
    .backgroundColor('#2C2C2C')
    .borderRadius(16)
    .padding({
      left: 24,
      right: 24,
      top: 20,
      bottom: 18
    })
  }

  private async saveImage() {
    const photoAccess = photoAccessHelper.getPhotoAccessHelper(getContext(this))
    const uri = await photoAccess.createAsset(photoAccessHelper.PhotoType.IMAGE, "png")
    const file = await fs.open(uri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
    const packer = image.createImagePacker()
    await packer.packToFile(this.pixelMap, file.fd, {
      format: "image/png",
      quality: 100
    })
    await packer.release()
    await fs.close(file)
  }
}

// </editor-fold>

// <editor-fold defaultstate="collapsed" desc="横屏">

@Component
struct PLVSAMoreShareLayoutLand {
  controller: CustomDialogController = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  private readonly webController = new PLVWebController()
  @State private posterUrl: string = ""
  private saveImageController: CustomDialogController | undefined = undefined
  private readonly plvsa_more_share_poster_web = 'plvsa_more_share_poster_web'
  private readonly posterHeight = px2vp(display.getDefaultDisplaySync().height) - 32
  private readonly posterWidth = this.posterHeight / 16 * 9

  async aboutToAppear(): Promise<void> {
    const posterUrl = await runCatching(this.sdk.interactManager.invitePoster.getInvitePosterUrl())
    if (posterUrl.success === true) {
      this.posterUrl = posterUrl.data
      this.webController.loadUrlCatch(this.posterUrl)
    } else {
      PLVLogger.error(TAG, `load invite poster fail: ${posterUrl.error.message}`)
    }
  }

  build() {
    RelativeContainer() {
      Stack() {
        Stack() {
          PLVSimpleWeb({
            controller: this.webController,
            src: this.posterUrl
          })
            .id(this.plvsa_more_share_poster_web)
            .width(this.posterWidth)
            .height(this.posterHeight)
        }
        .width(this.posterWidth)
        .height(this.posterHeight)
        .borderRadius(8)
        .clip(true)
      }
      .id('plvsa_more_share_poster_container')
      .margin({
        top: 16,
        bottom: 16
      })
      .alignRules({
        center: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Center },
        left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
        right: { anchor: 'plvsa_more_share_action_layout', align: HorizontalAlign.Start },
      })

      Column() {
        Grid() {
          GridItem() {
            ShareActionButton({
              image: $r('app.media.plvsa_more_share_action_save_image_icon'),
              name: $r('app.string.plvsa_more_share_action_save_image')
            })
              .onClick(() => this.onClickSaveImage())
          }

          GridItem() {
            ShareActionButton({
              image: $r('app.media.plvsa_more_share_action_copy_link_icon'),
              name: $r('app.string.plvsa_more_share_action_copy_link')
            })
              .onClick(() => this.onClickCopyLink())
          }
        }
        .layoutWeight(1)
        .columnsTemplate('1fr 1fr')

        Button($r('app.string.plvsa_more_share_action_cancel'))
          .width(240)
          .height(40)
          .margin({
            top: 18
          })
          .fontColor('#ffffff')
          .fontSize(14)
          .backgroundColor('#19ffffff')
          .borderRadius(30)
          .onClick(() => {
            this.controller.close()
          })
      }
      .id('plvsa_more_share_action_layout')
      .width(320)
      .height('100%')
      .padding({
        left: 25,
        right: 25,
        top: 28,
        bottom: 28
      })
      .backgroundColor('#2C2C2C')
      .borderRadius({
        topLeft: 16,
        bottomLeft: 16
      })
      .alignRules({
        right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#80464646')
  }

  private async onClickSaveImage() {
    const pixelMapResult = await runCatching(this.getUIContext()
      .getComponentSnapshot()
      .get(this.plvsa_more_share_poster_web))
    if (pixelMapResult.success === false) {
      PLVLogger.error(TAG, `saveImage failed: ${pixelMapResult.error.message}`)
      PLVToastUtils.shortShow($r('app.string.plvsa_more_share_action_save_image_fail_toast'))
      return
    }
    this.saveImageController = new CustomDialogController({
      builder: SaveImageDialogLand({
        pixelMap: pixelMapResult.data
      }),
      customStyle: true
    })
    this.saveImageController.open()
  }

  private async onClickCopyLink() {
    const watchUrlResult = await runCatching(this.sdk.interactManager.invitePoster.getLiveWatchUrl())
    if (watchUrlResult.success === true) {
      const watchUrl = watchUrlResult.data
      await PLVUtils.copyText(watchUrl)
      PLVToastUtils.shortShow($r('app.string.plvsa_chat_copy_success'))
    }
  }
}

@CustomDialog
struct SaveImageDialogLand {
  controller?: CustomDialogController = lateInit()
  pixelMap: PixelMap = lateInit()

  build() {
    Column() {
      Stack() {
        Image(this.pixelMap)
          .aspectRatio(9 / 16)
          .objectFit(ImageFit.Contain)
      }
      .layoutWeight(1)
      .margin({
        bottom: 20
      })

      SaveButton({
        icon: SaveIconStyle.FULL_FILLED,
        text: SaveDescription.SAVE_IMAGE
      })
        .onClick(async () => {
          const result = await runCatching(this.saveImage())
          if (result.success === true) {
            PLVToastUtils.shortShow($r('app.string.plvsa_more_share_action_save_image_success_toast'))
            this.controller?.close()
          } else {
            PLVLogger.error(TAG, `saveImage failed: ${result.error.message}`)
            PLVToastUtils.shortShow($r('app.string.plvsa_more_share_action_save_image_fail_toast'))
          }
        })
    }
    .height(px2vp(display.getDefaultDisplaySync().height) - 48)
    .backgroundColor('#2C2C2C')
    .borderRadius(16)
    .padding({
      left: 24,
      right: 24,
      top: 20,
      bottom: 18
    })
  }

  private async saveImage() {
    const photoAccess = photoAccessHelper.getPhotoAccessHelper(getContext(this))
    const uri = await photoAccess.createAsset(photoAccessHelper.PhotoType.IMAGE, "png")
    const file = await fs.open(uri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
    const packer = image.createImagePacker()
    await packer.packToFile(this.pixelMap, file.fd, {
      format: "image/png",
      quality: 100
    })
    await packer.release()
    await fs.close(file)
  }
}

// </editor-fold>

@Component
struct ShareActionButton {
  image: Resource = lateInit()
  name: Resource = lateInit()

  build() {
    Column() {
      Image(this.image)
        .width(52)
        .height(52)
        .padding(2)
      Text(this.name)
        .fontColor('#99F0F1F5')
        .fontSize(12)
    }
  }
}