import {
  IPLVCanReplyEvent,
  PLVChatImgEvent,
  PLVChatroomError,
  PLVChatroomErrorCode,
  PLVCommonConstants,
  PLVEmotionEvent,
  PLVEmotionImageBean,
  PLVHistoryChatImgEvent,
  PLVHistoryFileShareEvent,
  PLVHistorySpeakEvent,
  PLVLiveSceneSDK,
  PLVLocalQuizEvent,
  PLVLocalSpeakEvent,
  PLVLogger,
  PLVSpeakEvent,
  PLVToastUtils
} from '@polyvharmony/live-scenes-sdk';
import { lateInit, MutableObserver, PLVMediaPlayerAppContext, runCatching } from '@polyvharmony/media-player-sdk';
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus';
import { KeyboardAvoidMode, LengthUnit } from '@kit.ArkUI';
import { ClickType, ItemInfo, ItemType, photoAccessHelper, } from '@kit.MediaLibraryKit';
import { PhotoPickerComponent, PickerController, SelectMode } from '@ohos.file.PhotoPickerComponent';
import { PLVLWCommonDef } from '../../../../common/PLVLWCommonDef';
import { common } from '@kit.AbilityKit';

const TAG = 'PLVLWChatInputLayout'

@Component
export struct PLVLWChatInputLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private isVisible: boolean = false
  @State private isPortrait: boolean = true
  private isQuizTab: boolean = false
  private inputContent: string = ''
  private replyMessage: IPLVCanReplyEvent | undefined = undefined
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext;
    context.windowStage.getMainWindowSync().getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE);
    this.layoutDataBus.chatInputStatus.observe(status => {
      this.isVisible = status.inputVisible
      this.inputContent = status.inputContent
      this.replyMessage = status.replyMessage
    }).pushTo(this.observers)
    this.layoutDataBus.isPortrait.observe(it => this.isPortrait = it).pushTo(this.observers)
    this.layoutDataBus.chatTabStatus.observe(status => {
      this.isQuizTab = status.isSelectQuizTab
    }).pushTo(this.observers)
    this.layoutDataBus.registerBackPressedHandler(this.onBackPressed, PLVLWCommonDef.BACK_PRIORITY_CHAT_INPUT)
  }

  build() {
    if (this.isVisible) {
      Stack() {
        if (this.isPortrait) {
          PLVLWChatInputLayoutPort({
            onSendChatMessage: () => {
              if (!this.isQuizTab) {
                this.onSendChatMessage()
              } else {
                this.onSendQuizMessage()
              }
            },
            onSendEmotion: (emotion: PLVEmotionImageBean) => {
              this.onSendEmotionImage(emotion)
            },
            onSendImage: (image: string) => {
              this.onSendImage(image)
            }
          })
        } else {
          PLVLWChatInputLayoutLand({
            onSendChatMessage: () => {
              if (!this.isQuizTab) {
                this.onSendChatMessage()
              } else {
                this.onSendQuizMessage()
              }
            },
            onSendEmotion: (emotion: PLVEmotionImageBean) => {
              this.onSendEmotionImage(emotion)
            },
            onSendImage: (image: string) => {
              this.onSendImage(image)
            }
          })
        }
      }
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)
    }
  }

  private onSendChatMessage() {
    const content = this.inputContent
    const onSuccess = (event: PLVLocalSpeakEvent) => {
      this.layoutDataBus.onLocalChatEvent.setValue(event)
      this.layoutDataBus.chatInputStatus.mutate({
        inputVisible: false,
        emojiPanelVisible: false,
        inputContent: ''
      })
    }

    this.sdk.chatroomManager.speak(content, this.replyMessage?._replyQuoteBean?.get())
      .then((speakEvent) => {
        onSuccess(speakEvent)
      })
      .catch((err: PLVChatroomError) => {
        PLVLogger.printError(TAG, `speak fail`, err as Error)
        if (PLVChatroomErrorCode.USER_IS_BANNED == err.code) {
          // 被禁言也认为发言成功，并添加到聊天列表中，但不会广播给其他用户
          onSuccess(err.data as PLVLocalSpeakEvent)
        } else {
          PLVToastUtils.shortShow(`speak fail: ${err.message}`)
        }
      })
  }

  private async onSendEmotionImage(emotion: PLVEmotionImageBean): Promise<void> {
    const result = await runCatching(this.sdk.chatroomManager.sendEmotionImage(emotion))
    const onSuccess = (event: PLVEmotionEvent) => {
      this.layoutDataBus.onLocalChatEvent.setValue(event)
      this.layoutDataBus.chatInputStatus.mutate({
        inputVisible: false,
        emojiPanelVisible: false
      })
    }

    if (result.success === true) {
      onSuccess(result.data)
    } else {
      if (result.error instanceof PLVChatroomError) {
        const err = result.error
        PLVLogger.printError(TAG, `sendEmotionImage fail`, err as Error)
        if (PLVChatroomErrorCode.USER_IS_BANNED === err.code) {
          // 被禁言也认为发言成功，并添加到聊天列表中，但不会广播给其他用户
          onSuccess(err.data as PLVEmotionEvent)
        } else {
          PLVToastUtils.shortShow(`speak fail: ${err.message}`)
        }
      } else {
        PLVToastUtils.shortShow(`speak fail: ${result.error.message}`)
      }
    }
  }

  private async onSendImage(image: string): Promise<void> {
    const result = await runCatching(this.sdk?.chatroomManager.sendLocalImage(image))
    const onSuccess = (event: PLVChatImgEvent) => {
      this.layoutDataBus.onLocalChatEvent.setValue(event)
      this.layoutDataBus.chatInputStatus.mutate({
        inputVisible: false,
        emojiPanelVisible: false
      })
    }

    if (result.success === true) {
      onSuccess(result.data)
    } else {
      if (result.error instanceof PLVChatroomError) {
        const err = result.error
        PLVLogger.printError(TAG, `sendEmotionImage fail`, err as Error)
        if (PLVChatroomErrorCode.USER_IS_BANNED === err.code) {
          // 被禁言也认为发言成功，并添加到聊天列表中，但不会广播给其他用户
          onSuccess(err.data as PLVChatImgEvent)
        } else {
          PLVToastUtils.shortShow(`speak fail: ${err.message}`)
        }
      } else {
        PLVToastUtils.shortShow(`speak fail: ${result.error.message}`)
      }
    }
  }

  private onSendQuizMessage() {
    const content = this.inputContent
    const onSuccess = (event: PLVLocalQuizEvent) => {
      this.layoutDataBus.onLocalChatEvent.setValue(event)
      this.layoutDataBus.chatInputStatus.mutate({
        inputVisible: false,
        emojiPanelVisible: false,
        inputContent: ''
      })
    }

    this.sdk.chatroomManager.quiz(content)
      .then((quizEvent) => {
        onSuccess(quizEvent)
      })
      .catch((err: PLVChatroomError) => {
        PLVLogger.printError(TAG, `quiz fail`, err as Error)
        PLVToastUtils.shortShow(`quiz fail: ${err.message}`)
      })
  }

  private readonly onBackPressed = (): boolean => {
    if (this.isVisible) {
      this.layoutDataBus.chatInputStatus.mutate({
        inputVisible: false,
        emojiPanelVisible: false
      })
      return true
    }
    return false
  }

  aboutToDisappear(): void {
    this.layoutDataBus.unregisterBackPressedHandler(this.onBackPressed)
    MutableObserver.disposeAll(this.observers)
  }
}

@Component
struct PLVLWChatInputLayoutPort {
  onSendChatMessage: () => void = lateInit()
  onSendEmotion: (emotion: PLVEmotionImageBean) => void = lateInit()
  onSendImage: (image: string) => void = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private hasQuizTab: boolean = false
  @State private isQuizTab: boolean = false
  @State private emojiPanelVisible: boolean = false
  @State private inputContent: string = ''
  @State private replyMessage: IPLVCanReplyEvent | undefined = undefined
  @State private isFocusInput: boolean = false
  @State private localImagePickerVisible: boolean = false
  private readonly localImagePickerDialog = new CustomDialogController({
    builder: PLVLWChatLocalImageSelectDialog({
      localImagePickerVisible: this.localImagePickerVisible,
      onSelectImage: (image: string) => {
        this.onSendImage(image)
        this.localImagePickerDialog.close()
      }
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true
  })
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.layoutDataBus.chatInputStatus.observe(status => {
      this.emojiPanelVisible = status.emojiPanelVisible
      this.inputContent = status.inputContent
      this.replyMessage = status.replyMessage
    }).pushTo(this.observers)
    this.layoutDataBus.chatTabStatus.observe(status => {
      this.hasQuizTab = status.isEnableQuizTab
      this.isQuizTab = status.isSelectQuizTab
    }).pushTo(this.observers)
  }

  build() {
    RelativeContainer() {
      if (this.replyMessage && !this.isQuizTab) {
        Column()
          .id('plvlw_chat_input_layout_reply_mask')
          .width(PLVCommonConstants.FULL_PERCENT)
          .backgroundColor('#000000')
          .alignRules({
            top: { anchor: 'plvlw_chat_input_layout_reply_layout', align: VerticalAlign.Top },
            bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
          })

        Row() {
          Text(resolveReplyDisplayContent(this.replyMessage, this.sdk))
            .id('plvlw_chat_input_layout_reply_content')
            .constraintSize({
              maxWidth: 'calc(100% - 24vp)'
            })
            .fontSize(12)
            .fontColor('#FFFFFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .ellipsisMode(EllipsisMode.END)

          Blank()

          Image($r('app.media.plvlw_chatroom_input_reply_close_icon'))
            .id('plvlw_chat_input_layout_reply_close')
            .width(16)
            .height(16)
            .onClick(() => {
              this.layoutDataBus.chatInputStatus.mutate({
                replyMessage: undefined
              })
            })
        }
        .id('plvlw_chat_input_layout_reply_layout')
        .width(PLVCommonConstants.FULL_PERCENT)
        .padding(16)
        .alignRules({
          bottom: { anchor: 'plvlw_chat_input_layout', align: VerticalAlign.Top },
        })
      }

      Column() {
        Row() {
          if (this.hasQuizTab) {
            Image(this.isQuizTab ? $r('app.media.plvlw_chatroom_quiz_icon_selected_dark') : $r('app.media.plvlw_chatroom_quiz_icon_not_selected_dark'))
              .width(20)
              .height(20)
              .onClick(() => {
                this.layoutDataBus.chatTabStatus.mutate({
                  isSelectQuizTab: !this.isQuizTab
                })
              })

            Blank().width(8)

            Divider()
              .width(1)
              .height(14)
              .backgroundColor('#33333333')

            Blank().width(8)
          }

          TextInput({
            placeholder: this.isQuizTab ? $r('app.string.plvlw_chat_input_tips_quiz') : $r('app.string.plvlw_tool_bar_chat_input_hint'),
            text: this.inputContent
          })
            .id('plvlw_chat_input_view')
            .layoutWeight(1)
            .maxLength(2000)
            .padding(0)
            .backgroundColor(Color.Transparent)
            .borderRadius(0)
            .onAppear(() => {
              if (!this.emojiPanelVisible) {
                focusControl.requestFocus('plvlw_chat_input_view')
              }
            })
            .onFocus(() => {
              this.isFocusInput = true
              this.layoutDataBus.chatInputStatus.mutate({
                emojiPanelVisible: false
              })
            })
            .onBlur(() => {
              setTimeout(() => {
                this.isFocusInput = false
              }, 20)
            })
            .onChange(content => {
              this.layoutDataBus.chatInputStatus.mutate({
                inputContent: content
              })
            })
            .onSubmit(() => {
              this.onSendChatMessage()
            })
        }
        .borderRadius(8)
        .backgroundColor($r('app.color.plvlw_chat_input_edit_text_background'))
        .padding({
          left: 12,
          right: 12,
          top: 8,
          bottom: 8
        })

        Row() {
          if (!this.isQuizTab) {
            Image(this.emojiPanelVisible ? $r('app.media.plvlw_chatroom_sel_keyboard') : $r('app.media.plvlw_chatroom_sel_emoji'))
              .width(20)
              .height(20)
              .margin({
                left: 4
              })
              .onClick(() => {
                if (!this.emojiPanelVisible && this.isFocusInput) {
                  this.getUIContext().getFocusController().clearFocus()
                }
                this.layoutDataBus.chatInputStatus.mutate({
                  emojiPanelVisible: !this.emojiPanelVisible
                })
              })

            Image($r('app.media.plvlw_chatroom_sel_img'))
              .width(20)
              .height(20)
              .margin({
                left: 20
              })
              .onClick(() => {
                this.localImagePickerDialog.open()
              })
          }

          Blank()

          Button($r('app.string.plvlw_chat_send'))
            .height(28)
            .constraintSize({
              minWidth: 60
            })
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor($r('app.color.plvlw_theme_bg_blue'))
            .borderRadius(16)
            .onClick(() => {
              this.onSendChatMessage()
            })

        }
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(28)
        .margin({
          top: 12
        })

        if (this.emojiPanelVisible && !this.isQuizTab) {
          PLVLWChatEmotionLayout({
            onClickEmotionImage: (emotion: PLVEmotionImageBean) => {
              this.onSendEmotion(emotion)
            }
          })
            .width(PLVCommonConstants.FULL_PERCENT)
            .height(323)
            .margin({
              top: 16
            })
        }

      }
      .id('plvlw_chat_input_layout')
      .backgroundColor($r('app.color.plvlw_chat_input_window_background'))
      .padding({
        top: 12,
        bottom: 12,
        left: 16,
        right: 16
      })
      .borderRadius({
        topLeft: 16,
        topRight: 16
      })
      .alignRules({
        start: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
        end: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End },
        bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
      })
      .onClick(() => {
        // stop
      })
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
    .onClick(() => {
      if (this.isFocusInput) {
        this.getUIContext().getFocusController().clearFocus()
      } else {
        this.layoutDataBus.chatInputStatus.mutate({
          inputVisible: false
        })
      }
    })
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}

@Component
struct PLVLWChatInputLayoutLand {
  onSendChatMessage: () => void = lateInit()
  onSendEmotion: (emotion: PLVEmotionImageBean) => void = lateInit()
  onSendImage: (image: string) => void = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private hasQuizTab: boolean = false
  @State private isQuizTab: boolean = false
  @State private emojiPanelVisible: boolean = false
  @State private inputContent: string = ''
  @State private replyMessage: IPLVCanReplyEvent | undefined = undefined
  @State private isFocusInput: boolean = false
  @State private localImagePickerVisible: boolean = false
  private readonly localImagePickerDialog = new CustomDialogController({
    builder: PLVLWChatLocalImageSelectDialog({
      localImagePickerVisible: this.localImagePickerVisible,
      onSelectImage: (image: string) => {
        this.onSendImage(image)
        this.localImagePickerDialog.close()
      }
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true
  })
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.layoutDataBus.chatInputStatus.observe(status => {
      this.emojiPanelVisible = status.emojiPanelVisible
      this.inputContent = status.inputContent
      this.replyMessage = status.replyMessage
    }).pushTo(this.observers)
    this.layoutDataBus.chatTabStatus.observe(status => {
      this.hasQuizTab = status.isEnableQuizTab
      this.isQuizTab = status.isSelectQuizTab
    }).pushTo(this.observers)
  }

  build() {
    RelativeContainer() {
      if (this.replyMessage && !this.isQuizTab) {
        Column()
          .id('plvlw_chat_input_layout_reply_mask')
          .width(PLVCommonConstants.FULL_PERCENT)
          .backgroundColor('#000000')
          .alignRules({
            top: { anchor: 'plvlw_chat_input_layout_reply_layout', align: VerticalAlign.Top },
            bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
          })

        Row() {
          Text(resolveReplyDisplayContent(this.replyMessage, this.sdk))
            .id('plvlw_chat_input_layout_reply_content')
            .constraintSize({
              maxWidth: 'calc(100% - 24vp)'
            })
            .fontSize(12)
            .fontColor('#FFFFFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .ellipsisMode(EllipsisMode.END)

          Blank()

          Image($r('app.media.plvlw_chatroom_input_reply_close_icon'))
            .id('plvlw_chat_input_layout_reply_close')
            .width(16)
            .height(16)
            .onClick(() => {
              this.layoutDataBus.chatInputStatus.mutate({
                replyMessage: undefined
              })
            })
        }
        .id('plvlw_chat_input_layout_reply_layout')
        .width(PLVCommonConstants.FULL_PERCENT)
        .padding(16)
        .alignRules({
          bottom: { anchor: 'plvlw_chat_input_layout', align: VerticalAlign.Top },
        })
      }

      Column() {
        RelativeContainer() {
          Row() {
            Image(this.emojiPanelVisible ? $r('app.media.plvlw_chatroom_sel_keyboard') : $r('app.media.plvlw_chatroom_sel_emoji'))
              .width(20)
              .height(20)
              .margin({
                left: 4
              })
              .onClick(() => {
                if (!this.emojiPanelVisible && this.isFocusInput) {
                  this.getUIContext().getFocusController().clearFocus()
                }
                this.layoutDataBus.chatInputStatus.mutate({
                  emojiPanelVisible: !this.emojiPanelVisible
                })
              })

            Image($r('app.media.plvlw_chatroom_sel_img'))
              .width(20)
              .height(20)
              .margin({
                left: 20
              })
              .onClick(() => {
                this.localImagePickerDialog.open()
              })
          }
          .id('plvlw_chat_emoji_image_row')
          .visibility(!this.isQuizTab ? Visibility.Visible : Visibility.None)
          .height(28)
          .alignRules({
            start: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
            center: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Center }
          })

          Row() {
            if (this.hasQuizTab) {
              Image(this.isQuizTab ? $r('app.media.plvlw_chatroom_quiz_icon_selected_dark') : $r('app.media.plvlw_chatroom_quiz_icon_not_selected_dark'))
                .width(20)
                .height(20)
                .onClick(() => {
                  this.layoutDataBus.chatTabStatus.mutate({
                    isSelectQuizTab: !this.isQuizTab
                  })
                })

              Blank().width(8)

              Divider()
                .width(1)
                .height(14)
                .backgroundColor('#33333333')

              Blank().width(8)
            }

            TextInput({
              placeholder: this.isQuizTab ? $r('app.string.plvlw_chat_input_tips_quiz') : $r('app.string.plvlw_tool_bar_chat_input_hint'),
              text: this.inputContent
            })
              .id('plvlw_chat_input_view')
              .maxLength(2000)
              .padding(0)
              .backgroundColor(Color.Transparent)
              .borderRadius(0)
              .onAppear(() => {
                if (!this.emojiPanelVisible) {
                  focusControl.requestFocus('plvlw_chat_input_view')
                }
              })
              .onFocus(() => {
                this.isFocusInput = true
                this.layoutDataBus.chatInputStatus.mutate({
                  emojiPanelVisible: false
                })
              })
              .onBlur(() => {
                setTimeout(() => {
                  this.isFocusInput = false
                }, 20)
              })
              .onChange(content => {
                this.layoutDataBus.chatInputStatus.mutate({
                  inputContent: content
                })
              })
              .onSubmit(() => {
                this.onSendChatMessage()
              })
          }
          .borderRadius(8)
          .backgroundColor($r('app.color.plvlw_chat_input_edit_text_background'))
          .padding({
            left: 12,
            right: 12,
            top: 8,
            bottom: 8
          })
          .margin({
            left: 20,
            right: 20
          })
          .alignRules({
            start: { anchor: 'plvlw_chat_emoji_image_row', align: HorizontalAlign.End },
            end: { anchor: 'plvlw_chat_send_button', align: HorizontalAlign.Start },
            center: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Center }
          })

          Button($r('app.string.plvlw_chat_send'))
            .id('plvlw_chat_send_button')
            .height(28)
            .constraintSize({
              minWidth: 60
            })
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor($r('app.color.plvlw_theme_bg_blue'))
            .borderRadius(16)
            .onClick(() => {
              this.onSendChatMessage()
            })
            .alignRules({
              end: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End },
              center: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Center }
            })
        }
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(36)

        if (this.emojiPanelVisible && !this.isQuizTab) {
          PLVLWChatEmotionLayout({
            onClickEmotionImage: (emotion: PLVEmotionImageBean) => {
              this.onSendEmotion(emotion)
            }
          })
            .width(PLVCommonConstants.FULL_PERCENT)
            .height(227)
            .margin({
              top: 16
            })
        }

      }
      .id('plvlw_chat_input_layout')
      .backgroundColor($r('app.color.plvlw_chat_input_window_background'))
      .padding({
        top: 12,
        bottom: 12,
        left: 16,
        right: 16
      })
      .borderRadius({
        topLeft: 16,
        topRight: 16
      })
      .alignRules({
        start: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
        end: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End },
        bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
      })
      .onClick(() => {
        // stop
      })
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
    .onClick(() => {
      if (this.isFocusInput) {
        this.getUIContext().getFocusController().clearFocus()
      } else {
        this.layoutDataBus.chatInputStatus.mutate({
          inputVisible: false
        })
      }
    })
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}

@Component
struct PLVLWChatEmotionLayout {
  onClickEmotionImage: (emotion: PLVEmotionImageBean) => void = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private emotionImages: PLVEmotionImageBean[] = []

  aboutToAppear(): void {
    this.emotionImages = this.sdk.chatroomManager.emotions ?? []
    this.sdk.chatroomManager.eventNotify.on('emotions', this.onEmotionImagesUpdate)
  }

  build() {
    Flex({
      direction: FlexDirection.Row,
      wrap: FlexWrap.Wrap,
      space: {
        cross: {
          value: 10,
          unit: LengthUnit.VP
        }
      }
    }) {
      ForEach(
        this.emotionImages,
        (emotion: PLVEmotionImageBean) => {
          Column() {
            Image(emotion.url)
              .width(54)
              .height(54)
            Text(emotion.title)
              .fontSize(12)
              .fontColor('#ADADC0')
          }
          .width('20%')
          .onClick(() => this.onClickEmotionImage(emotion))
        },
        (emotion: PLVEmotionImageBean) => emotion.id
      )
    }
  }

  private onEmotionImagesUpdate = (emotions: PLVEmotionImageBean[] | undefined) => {
    this.emotionImages = emotions ?? []
  }

  aboutToDisappear(): void {
    this.sdk.chatroomManager.eventNotify.off('emotions', this.onEmotionImagesUpdate)
  }
}

@CustomDialog
struct PLVLWChatLocalImageSelectDialog {
  onSelectImage: (image: string) => void = lateInit()
  @Link localImagePickerVisible: boolean
  controller: CustomDialogController = lateInit()
  @State private readonly pickerController: PickerController = new PickerController();

  aboutToAppear(): void {
    this.localImagePickerVisible = true
  }

  build() {
    PhotoPickerComponent({
      pickerOptions: {
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        selectMode: SelectMode.SINGLE_SELECT
      },
      onItemClicked: (itemInfo: ItemInfo, clickType: ClickType): boolean => {
        if (itemInfo.itemType === ItemType.CAMERA) {
          return true
        }
        return true
      },
      onSelect: (uri: string) => {
        this.onSelectImage(uri)
      },
      pickerController: this.pickerController
    })
      .width('100%')
      .height('80%')
  }

  aboutToDisappear(): void {
    this.localImagePickerVisible = false
  }
}

function resolveReplyDisplayContent(replyMessage: IPLVCanReplyEvent, sdk: PLVLiveSceneSDK): string {
  if (replyMessage instanceof PLVSpeakEvent && !replyMessage.isFileShareEvent()) {
    const nick = replyMessage.user?.nick ?? ''
    const message = replyMessage.values?.[0] ?? ''
    return `${nick}: ${message}`
  } else if (replyMessage instanceof PLVHistorySpeakEvent) {
    const nick = replyMessage.user?.nick ?? ''
    const message = replyMessage.content ?? ''
    return `${nick}: ${message}`
  } else if (replyMessage instanceof PLVLocalSpeakEvent) {
    const nick = sdk.channelData.viewerName ?? ''
    const message = replyMessage.speakMessage ?? ''
    return `${nick}: ${message}`
  } else if (replyMessage instanceof PLVChatImgEvent) {
    const nick = replyMessage.user?.nick ?? ''
    const message = PLVMediaPlayerAppContext.getString($r('app.string.plvlw_chat_pinned_announcement_image_alt'))
    return `${nick}: ${message}`
  } else if (replyMessage instanceof PLVHistoryChatImgEvent) {
    const nick = replyMessage.user?.nick ?? ''
    const message = PLVMediaPlayerAppContext.getString($r('app.string.plvlw_chat_pinned_announcement_image_alt'))
    return `${nick}: ${message}`
  } else if (replyMessage instanceof PLVEmotionEvent) {
    const nick = replyMessage.user?.nick ?? ''
    const message = PLVMediaPlayerAppContext.getString($r('app.string.plvlw_chat_pinned_announcement_image_alt'))
    return `${nick}: ${message}`
  } else if (replyMessage instanceof PLVSpeakEvent && replyMessage.isFileShareEvent()) {
    const nick = replyMessage.user?.nick ?? ''
    const message = replyMessage.fileData?.name ?? ''
    return `${nick}: ${message}`
  } else if (replyMessage instanceof PLVHistoryFileShareEvent) {
    const nick = replyMessage.user?.nick ?? ''
    const message = replyMessage.fileData?.name ?? ''
    return `${nick}: ${message}`
  } else {
    return ''
  }
}
