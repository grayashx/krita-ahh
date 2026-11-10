/*
 * SPDX-FileCopyrightText: 2026 Krita Mobile project contributors
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "KisMobileBridge.h"

#include "KisMainWindow.h"
#include "KisView.h"
#include "KisViewManager.h"
#include "KisRecentDocumentsModelWrapper.h"
#include "kis_node_manager.h"
#include "kis_node.h"
#include "kis_image.h"
#include "kis_layer.h"
#include "kis_paint_layer.h"
#include "kis_paintop_preset.h"
#include <KisResourceModel.h>
#include <KisResourceTypes.h>
#include <KisTagModel.h>
#include <KisTagResourceModel.h>
#include <KoCompositeOpRegistry.h>
#include <KoToolManager.h>
#include "kis_canvas_resource_provider.h"

#include <KoColor.h>

#include <QAction>
#include <QColor>
#include <QMap>
#include <QRegularExpression>
#include <QUrl>
#include <QVariantMap>
#include <functional>
#include <kactioncollection.h>

KisMobileBridge::KisMobileBridge(KisMainWindow *mainWindow)
    : QObject(mainWindow)
    , m_mainWindow(mainWindow)
{
    if (m_mainWindow) {
        connect(m_mainWindow, &KisMainWindow::activeViewChanged, this, [this]() {
            connectColorResourceSignals();
            Q_EMIT documentStateChanged();
            Q_EMIT colorsChanged();
        });
        connect(m_mainWindow, &KisMainWindow::loadCompleted, this, [this]() {
            connectColorResourceSignals();
            Q_EMIT documentStateChanged();
            Q_EMIT colorsChanged();
        });
        connectColorResourceSignals();
    }
}

void KisMobileBridge::connectColorResourceSignals()
{
    if (!m_mainWindow || !m_mainWindow->viewManager()) {
        return;
    }

    KisCanvasResourceProvider *resources =
        m_mainWindow->viewManager()->canvasResourceProvider();

    if (resources == m_connectedColorResources) {
        return;
    }

    if (m_connectedColorResources) {
        disconnect(m_connectedColorResources, nullptr, this, nullptr);
    }

    m_connectedColorResources = resources;
    if (!resources) {
        return;
    }

    connect(resources, &KisCanvasResourceProvider::sigFGColorChanged,
            this, [this](const KoColor &) { Q_EMIT colorsChanged(); });
    connect(resources, &KisCanvasResourceProvider::sigBGColorChanged,
            this, [this](const KoColor &) { Q_EMIT colorsChanged(); });
    connect(resources, &QObject::destroyed, this, [this]() {
        m_connectedColorResources = nullptr;
    });
}

bool KisMobileBridge::triggerAction(const QString &actionId) const
{
    if (!m_mainWindow || actionId.isEmpty()) {
        return false;
    }

    QAction *action = m_mainWindow->actionCollection()->action(actionId);
    if (!action || !action->isEnabled()) {
        return false;
    }

    action->trigger();
    return true;
}

bool KisMobileBridge::isActionEnabled(const QString &actionId) const
{
    if (!m_mainWindow || actionId.isEmpty()) {
        return false;
    }

    QAction *action = m_mainWindow->actionCollection()->action(actionId);
    return action && action->isEnabled();
}

bool KisMobileBridge::hasActiveDocument() const
{
    return m_mainWindow && m_mainWindow->activeView()
        && m_mainWindow->activeView()->document();
}

qreal KisMobileBridge::brushSize() const
{
    if (!hasActiveDocument()) return 18.0;
    KisCanvasResourceProvider *resources = m_mainWindow->viewManager()->canvasResourceProvider();
    return resources ? resources->size() : 18.0;
}

qreal KisMobileBridge::brushOpacity() const
{
    if (!hasActiveDocument()) return 100.0;
    KisCanvasResourceProvider *resources = m_mainWindow->viewManager()->canvasResourceProvider();
    return resources ? resources->opacity() * 100.0 : 100.0;
}

bool KisMobileBridge::setBrushSize(qreal size) const
{
    if (!hasActiveDocument()) return false;
    KisCanvasResourceProvider *resources = m_mainWindow->viewManager()->canvasResourceProvider();
    if (!resources) return false;
    resources->setSize(qBound<qreal>(0.01, size, 100000.0));
    return true;
}

bool KisMobileBridge::setBrushOpacity(qreal opacityPercent) const
{
    if (!hasActiveDocument()) return false;
    KisCanvasResourceProvider *resources = m_mainWindow->viewManager()->canvasResourceProvider();
    if (!resources) return false;
    resources->setOpacity(qBound<qreal>(0.0, opacityPercent, 100.0) / 100.0);
    return true;
}

bool KisMobileBridge::setForegroundColor(const QString &colorName) const
{
    if (!hasActiveDocument()) return false;
    const QColor color(colorName);
    if (!color.isValid()) return false;
    KisCanvasResourceProvider *resources = m_mainWindow->viewManager()->canvasResourceProvider();
    if (!resources) return false;
    KoColor foreground = resources->fgColor();
    foreground.fromQColor(color);
    resources->setFGColor(foreground);
    return true;
}



bool KisMobileBridge::setBackgroundColor(const QString &colorName) const
{
    if (!hasActiveDocument()) return false;
    const QColor color(colorName);
    if (!color.isValid()) return false;
    KisCanvasResourceProvider *resources = m_mainWindow->viewManager()->canvasResourceProvider();
    if (!resources) return false;
    KoColor background = resources->bgColor();
    background.fromQColor(color);
    resources->setBGColor(background);
    return true;
}

QString KisMobileBridge::foregroundColor() const
{
    if (!hasActiveDocument()) return QStringLiteral("#000000");
    KisCanvasResourceProvider *resources = m_mainWindow->viewManager()->canvasResourceProvider();
    if (!resources) return QStringLiteral("#000000");
    QColor color;
    resources->fgColor().toQColor(&color);
    return color.name(QColor::HexRgb);
}

QString KisMobileBridge::backgroundColor() const
{
    if (!hasActiveDocument()) return QStringLiteral("#ffffff");
    KisCanvasResourceProvider *resources = m_mainWindow->viewManager()->canvasResourceProvider();
    if (!resources) return QStringLiteral("#ffffff");
    QColor color;
    resources->bgColor().toQColor(&color);
    return color.name(QColor::HexRgb);
}


QVariantList KisMobileBridge::recentColors() const
{
    QVariantList result;
    if (!hasActiveDocument()) {
        return result;
    }

    KisCanvasResourceProvider *resources =
        m_mainWindow->viewManager()->canvasResourceProvider();
    if (!resources) {
        return result;
    }

    const QList<KoColor> history = resources->colorHistoryColors();
    for (const KoColor &entry : history) {
        QColor color;
        entry.toQColor(&color);
        if (color.isValid()) {
            result.append(color.name(QColor::HexRgb));
        }
    }

    return result;
}

bool KisMobileBridge::swapColors() const
{
    if (!hasActiveDocument()) return false;
    KisCanvasResourceProvider *resources = m_mainWindow->viewManager()->canvasResourceProvider();
    if (!resources) return false;
    const KoColor foreground = resources->fgColor();
    const KoColor background = resources->bgColor();
    resources->setFGColor(background);
    resources->setBGColor(foreground);
    return true;
}

bool KisMobileBridge::setEraserMode(bool enabled) const
{
    if (!hasActiveDocument()) return false;
    KisCanvasResourceProvider *resources = m_mainWindow->viewManager()->canvasResourceProvider();
    if (!resources) return false;
    resources->setEraserMode(enabled);
    return true;
}


bool KisMobileBridge::setActiveTool(const QString &toolName) const
{
    if (!hasActiveDocument() || !m_mainWindow->viewManager()) return false;

    // Keep the QML surface label-based. Only expose tools that are known to
    // exist in Krita's registered tool factories.
    // These IDs are registered by Krita's native default-tools plugin.
    // The mobile UI exposes a small, task-focused subset rather than a desktop
    // toolbox full of rarely used controls.
    static const QMap<QString, QString> toolIds {
        {QStringLiteral("Brush"), QStringLiteral("KritaShape/KisToolBrush")},
        {QStringLiteral("Eraser"), QStringLiteral("KritaShape/KisToolBrush")},
        {QStringLiteral("Picker"), QStringLiteral("KritaSelected/KisToolColorSampler")},
        {QStringLiteral("Fill"), QStringLiteral("KritaFill/KisToolFill")},
        {QStringLiteral("Gradient"), QStringLiteral("KritaFill/KisToolGradient")},
        {QStringLiteral("Line"), QStringLiteral("KritaShape/KisToolLine")},
        {QStringLiteral("Ellipse"), QStringLiteral("KritaShape/KisToolEllipse")},
        {QStringLiteral("Rectangle"), QStringLiteral("KritaShape/KisToolRectangle")},
        {QStringLiteral("Pencil"), QStringLiteral("KisToolPencil")},
        {QStringLiteral("Path"), QStringLiteral("KisToolPath")},
        {QStringLiteral("Text"), QStringLiteral("SvgTextTool")},
        {QStringLiteral("Move"), QStringLiteral("KritaTransform/KisToolMove")}
    };

    const auto it = toolIds.constFind(toolName);
    if (it == toolIds.cend()) return false;

    KoToolManager *toolManager = m_mainWindow->viewManager()->toolManager();
    KisCanvasResourceProvider *resources =
        m_mainWindow->viewManager()->canvasResourceProvider();
    if (!toolManager || !resources) return false;

    toolManager->switchToolRequested(it.value());
    if (toolManager->activeToolId() != it.value()) {
        return false;
    }

    // Eraser is the native brush tool with Krita's eraser mode enabled.
    // Selecting any other tool clears the mode so it cannot unexpectedly
    // remain active when the artist returns to the brush.
    resources->setEraserMode(toolName == QStringLiteral("Eraser"));
    return true;
}


bool KisMobileBridge::openRecentDocument(int index) const
{
    if (!m_mainWindow || index < 0) return false;

    KisRecentDocumentsModelWrapper *recentFiles = KisRecentDocumentsModelWrapper::instance();
    if (!recentFiles) return false;

    QStandardItemModel &model = recentFiles->model();
    if (index >= model.rowCount()) return false;

    const QUrl url = model.index(index, 0).data(Qt::UserRole + 1).toUrl();
    if (url.isEmpty()) return false;

    const QString path = url.isLocalFile() ? url.toLocalFile() : url.toString();
    return m_mainWindow->openDocument(path, KisMainWindow::None);
}

bool KisMobileBridge::saveDocument(bool exportImage) const
{
    if (!hasActiveDocument()) return false;
    return m_mainWindow->saveDocument(
        m_mainWindow->activeView()->document(),
        false,
        exportImage);
}

void KisMobileBridge::showHomeScreen() const
{
    if (m_mainWindow) {
        m_mainWindow->showWelcomeScreen(true);
    }
}


QVariantList KisMobileBridge::brushPresets(const QString &filter, const QString &tagUrl) const
{
    QVariantList result;
    if (!hasActiveDocument()) return result;

    KisResourceModel model(ResourceType::PaintOpPresets);
    const QString needle = filter.trimmed();
    KisCanvasResourceProvider *resources = m_mainWindow->viewManager()->canvasResourceProvider();
    const KisPaintOpPresetSP currentPreset = resources ? resources->currentPreset() : KisPaintOpPresetSP();
    const int currentPresetId = currentPreset ? currentPreset->resourceId() : -1;
    const QString favoritesUrl = QStringLiteral("★ My Favorites");

    for (int row = 0; row < model.rowCount(); ++row) {
        const QModelIndex index = model.index(row, 0);
        const int resourceId = index.data(Qt::UserRole + KisAbstractResourceModel::Id).toInt();
        const QString name = index.data(Qt::UserRole + KisAbstractResourceModel::Name).toString();
        if (!needle.isEmpty() && !name.contains(needle, Qt::CaseInsensitive)) continue;

        bool isFavorite = false;
        bool matchesTag = tagUrl.isEmpty();
        const QVector<KisTagSP> tags = model.tagsForResource(resourceId);
        for (const KisTagSP &tag : tags) {
            if (!tag) continue;
            if (tag->url() == favoritesUrl) isFavorite = true;
            if (tag->url() == tagUrl) matchesTag = true;
        }
        if (!matchesTag) continue;

        QVariantMap item;
        item.insert(QStringLiteral("id"), resourceId);
        item.insert(QStringLiteral("name"), name);
        item.insert(QStringLiteral("favorite"), isFavorite);
        item.insert(QStringLiteral("current"), resourceId == currentPresetId);
        item.insert(QStringLiteral("dirty"),
                    index.data(Qt::UserRole + KisAbstractResourceModel::Dirty).toBool());
        item.insert(QStringLiteral("filename"),
                    index.data(Qt::UserRole + KisAbstractResourceModel::Filename).toString());
        result.append(item);
    }
    return result;
}

QVariantList KisMobileBridge::brushTags() const
{
    QVariantList result;
    if (!hasActiveDocument()) return result;

    KisTagModel model(ResourceType::PaintOpPresets);
    for (int row = 0; row < model.rowCount(); ++row) {
        const KisTagSP tag = model.tagForIndex(model.index(row, 0));
        if (!tag || !tag->active()) continue;

        QVariantMap item;
        item.insert(QStringLiteral("url"), tag->url());
        item.insert(QStringLiteral("name"), tag->name());
        item.insert(QStringLiteral("favorite"),
                    tag->url() == QStringLiteral("★ My Favorites"));
        result.append(item);
    }
    return result;
}

bool KisMobileBridge::setBrushFavorite(int resourceId, bool favorite) const
{
    if (!hasActiveDocument() || resourceId <= 0) return false;

    KisTagModel tags(ResourceType::PaintOpPresets);
    const KisTagSP favorites = tags.tagForUrl(QStringLiteral("★ My Favorites"));
    if (!favorites || !favorites->valid()) return false;

    KisTagResourceModel tagResources(ResourceType::PaintOpPresets);
    const QVector<int> ids{resourceId};
    return favorite
        ? tagResources.tagResources(favorites, ids)
        : tagResources.untagResources(favorites, ids);
}

bool KisMobileBridge::setBrushTag(int resourceId, const QString &tagUrl, bool tagged) const
{
    if (!hasActiveDocument() || resourceId <= 0 || tagUrl.trimmed().isEmpty()) return false;

    KisTagModel tags(ResourceType::PaintOpPresets);
    const KisTagSP tag = tags.tagForUrl(tagUrl);
    if (!tag || !tag->valid()) return false;

    KisTagResourceModel tagResources(ResourceType::PaintOpPresets);
    const QVector<int> ids{resourceId};
    return tagged
        ? tagResources.tagResources(tag, ids)
        : tagResources.untagResources(tag, ids);
}

bool KisMobileBridge::createBrushTag(const QString &name) const
{
    if (!hasActiveDocument() || name.trimmed().isEmpty()) return false;

    KisTagModel tags(ResourceType::PaintOpPresets);
    const KisTagSP tag = tags.addTag(name.trimmed(), false, QVector<KoResourceSP>());
    return tag && tag->valid();
}

bool KisMobileBridge::renameBrushPreset(int resourceId, const QString &name) const
{
    if (!hasActiveDocument() || resourceId <= 0 || name.trimmed().isEmpty()) return false;

    KisResourceModel model(ResourceType::PaintOpPresets);
    KoResourceSP resource = model.resourceForId(resourceId);
    if (!resource) return false;
    return model.renameResource(resource, name.trimmed());
}

bool KisMobileBridge::saveCurrentBrushPreset() const
{
    if (!hasActiveDocument()) return false;

    KisCanvasResourceProvider *resources = m_mainWindow->viewManager()->canvasResourceProvider();
    if (!resources) return false;
    const KisPaintOpPresetSP preset = resources->currentPreset();
    if (!preset || !preset->valid()) return false;

    KisResourceModel model(ResourceType::PaintOpPresets);
    preset->setDirty(true);
    const bool saved = preset->resourceId() > 0
        ? model.updateResource(preset)
        : model.addResource(preset);
    return saved;
}

bool KisMobileBridge::saveCurrentBrushPresetCopy(const QString &name) const
{
    if (!hasActiveDocument() || name.trimmed().isEmpty()) return false;

    KisCanvasResourceProvider *resources = m_mainWindow->viewManager()->canvasResourceProvider();
    if (!resources) return false;
    const KisPaintOpPresetSP current = resources->currentPreset();
    if (!current || !current->valid()) return false;

    KisPaintOpPresetSP copy = current->clone().dynamicCast<KisPaintOpPreset>();
    if (!copy) return false;

    const QString cleanName = name.trimmed();
    QString filename = cleanName;
    filename.replace(QRegularExpression(QStringLiteral("[^A-Za-z0-9_-]")), QStringLiteral("_"));
    if (filename.isEmpty()) filename = QStringLiteral("Brush");
    if (!filename.endsWith(copy->defaultFileExtension(), Qt::CaseInsensitive)) {
        filename.append(copy->defaultFileExtension());
    }

    copy->setResourceId(-1);
    copy->setName(cleanName);
    copy->setFilename(filename);
    copy->setValid(true);
    copy->setDirty(true);
    copy->setStorageLocation(QString());

    KisResourceModel model(ResourceType::PaintOpPresets);
    if (!model.addResourceDeduplicateFileName(copy, QString())) return false;

    resources->setPaintOpPreset(copy);
    resources->setEraserMode(false);
    return true;
}

bool KisMobileBridge::activateBrushPreset(int resourceId) const
{
    if (!hasActiveDocument() || resourceId <= 0) return false;

    KisResourceModel model(ResourceType::PaintOpPresets);
    const QModelIndex index = model.indexForResourceId(resourceId);
    if (!index.isValid()) return false;

    KisPaintOpPresetSP preset = model.resourceForIndex(index).dynamicCast<KisPaintOpPreset>();
    if (!preset) return false;

    KisCanvasResourceProvider *resources = m_mainWindow->viewManager()->canvasResourceProvider();
    if (!resources) return false;
    resources->setPaintOpPreset(preset);
    resources->setEraserMode(false);
    return true;
}

QVariantList KisMobileBridge::layers() const
{
    QVariantList result;
    if (!hasActiveDocument()) return result;

    KisImageSP image = m_mainWindow->activeView()->image();
    if (!image || !image->root()) return result;

    KisNodeSP active = m_mainWindow->viewManager()->activeNode();
    std::function<void(KisNodeSP)> appendChildren = [&](KisNodeSP parent) {
        for (KisNodeSP node = parent ? parent->firstChild() : KisNodeSP();
             node;
             node = node->nextSibling()) {
            QVariantMap item;
            item.insert(QStringLiteral("id"),
                        QString::number(reinterpret_cast<quintptr>(node.data()), 16));
            item.insert(QStringLiteral("name"), node->name());
            item.insert(QStringLiteral("visible"), node->visible());
            item.insert(QStringLiteral("opacity"), node->percentOpacity());
            item.insert(QStringLiteral("locked"), node->userLocked());
            item.insert(QStringLiteral("active"), node == active);

            KisLayer *layer = dynamic_cast<KisLayer*>(node.data());
            KisPaintLayer *paintLayer = dynamic_cast<KisPaintLayer*>(node.data());
            item.insert(QStringLiteral("isLayer"), layer != nullptr);
            item.insert(QStringLiteral("isPaintLayer"), paintLayer != nullptr);
            item.insert(QStringLiteral("blendModeId"),
                        layer ? layer->compositeOpId() : QString());
            item.insert(QStringLiteral("blendModeName"),
                        layer && layer->compositeOp()
                            ? layer->compositeOp()->description()
                            : QString());
            item.insert(QStringLiteral("alphaLocked"),
                        paintLayer ? paintLayer->alphaLocked() : false);
            item.insert(QStringLiteral("inheritAlpha"),
                        layer ? !layer->alphaChannelDisabled() : false);
            result.append(item);
            appendChildren(node);
        }
    };
    appendChildren(image->root());
    return result;
}

static KisNodeSP findMobileNode(KisImageSP image, const QString &id)
{
    bool ok = false;
    const quintptr nodeAddress = static_cast<quintptr>(id.toULongLong(&ok, 16));
    if (!image || !image->root() || !ok || !nodeAddress) return KisNodeSP();

    KisNodeSP found;
    std::function<void(KisNodeSP)> visit = [&](KisNodeSP parent) {
        for (KisNodeSP node = parent ? parent->firstChild() : KisNodeSP();
             node && !found;
             node = node->nextSibling()) {
            if (reinterpret_cast<quintptr>(node.data()) == nodeAddress) {
                found = node;
                return;
            }
            visit(node);
        }
    };
    visit(image->root());
    return found;
}

bool KisMobileBridge::activateLayer(const QString &id) const
{
    if (!hasActiveDocument()) return false;
    KisNodeSP node = findMobileNode(m_mainWindow->activeView()->image(), id);
    if (!node) return false;
    m_mainWindow->viewManager()->nodeManager()->slotUiActivatedNode(node);
    return true;
}

static bool selectSingleMobileNode(KisNodeManager *nodeManager, const KisNodeSP &node)
{
    if (!nodeManager || !node) return false;

    KisNodeList selectedNodes;
    selectedNodes.append(node);
    nodeManager->slotSetSelectedNodes(selectedNodes);
    if (nodeManager->activeNode() != node) {
        nodeManager->slotUiActivatedNode(node);
    }
    return nodeManager->activeNode() == node;
}

bool KisMobileBridge::setLayerVisible(const QString &id, bool visible) const
{
    if (!hasActiveDocument()) return false;
    KisNodeSP node = findMobileNode(m_mainWindow->activeView()->image(), id);
    KisNodeManager *nodeManager = m_mainWindow->viewManager()->nodeManager();
    if (!node || !selectSingleMobileNode(nodeManager, node)) return false;

    if (node->visible() != visible) nodeManager->toggleVisibility();
    return node->visible() == visible;
}

bool KisMobileBridge::renameLayer(const QString &id, const QString &name) const
{
    if (!hasActiveDocument() || name.trimmed().isEmpty()) return false;
    KisNodeSP node = findMobileNode(m_mainWindow->activeView()->image(), id);
    if (!node) return false;
    m_mainWindow->viewManager()->nodeManager()->setNodeName(node, name.trimmed());
    return true;
}

bool KisMobileBridge::removeLayer(const QString &id) const
{
    if (!hasActiveDocument()) return false;
    KisNodeSP node = findMobileNode(m_mainWindow->activeView()->image(), id);
    if (!node) return false;
    m_mainWindow->viewManager()->nodeManager()->removeSingleNode(node);
    return true;
}

bool KisMobileBridge::addPaintLayer() const
{
    if (!hasActiveDocument()) return false;
    return !m_mainWindow->viewManager()->nodeManager()->createPaintLayer().isNull();
}

bool KisMobileBridge::addGroupLayer() const
{
    if (!hasActiveDocument()) return false;
    return !m_mainWindow->viewManager()->nodeManager()
        ->createNode(QStringLiteral("KisGroupLayer")).isNull();
}

bool KisMobileBridge::addTransparencyMask() const
{
    if (!hasActiveDocument()) return false;
    return !m_mainWindow->viewManager()->nodeManager()
        ->createNode(QStringLiteral("KisTransparencyMask")).isNull();
}

bool KisMobileBridge::addFilterMask() const
{
    if (!hasActiveDocument()) return false;
    return !m_mainWindow->viewManager()->nodeManager()
        ->createNode(QStringLiteral("KisFilterMask"), false).isNull();
}

bool KisMobileBridge::duplicateLayer(const QString &id) const
{
    if (!hasActiveDocument()) return false;
    KisNodeSP node = findMobileNode(m_mainWindow->activeView()->image(), id);
    KisNodeManager *nodeManager = m_mainWindow->viewManager()->nodeManager();
    if (!node || !selectSingleMobileNode(nodeManager, node)) return false;
    nodeManager->duplicateActiveNode();
    return true;
}

bool KisMobileBridge::mergeLayerDown(const QString &id) const
{
    if (!hasActiveDocument()) return false;
    KisNodeSP node = findMobileNode(m_mainWindow->activeView()->image(), id);
    if (!node || !activateLayer(id)) return false;
    return triggerAction(QStringLiteral("merge_layer"));
}

QVariantList KisMobileBridge::layerBlendModes(const QString &id) const
{
    QVariantList result;
    if (!hasActiveDocument()) return result;

    KisNodeSP node = findMobileNode(m_mainWindow->activeView()->image(), id);
    KisLayer *layer = dynamic_cast<KisLayer*>(node.data());
    if (!layer || !layer->colorSpace()) return result;

    const QStringList commonModes {
        QStringLiteral("normal"),
        QStringLiteral("multiply"),
        QStringLiteral("screen"),
        QStringLiteral("overlay"),
        QStringLiteral("darken"),
        QStringLiteral("lighten"),
        QStringLiteral("burn"),
        QStringLiteral("dodge"),
        QStringLiteral("hard_light"),
        QStringLiteral("soft_light"),
        QStringLiteral("add"),
        QStringLiteral("difference"),
        QStringLiteral("color"),
        QStringLiteral("hue"),
        QStringLiteral("saturation")
    };

    const KoCompositeOpRegistry &registry = KoCompositeOpRegistry::instance();
    for (const QString &modeId : commonModes) {
        if (!layer->colorSpace()->hasCompositeOp(modeId)) continue;
        QVariantMap item;
        item.insert(QStringLiteral("id"), modeId);
        item.insert(QStringLiteral("name"), registry.getCompositeOpDisplayName(modeId));
        result.append(item);
    }
    return result;
}

bool KisMobileBridge::setLayerBlendMode(const QString &id, const QString &compositeOpId) const
{
    if (!hasActiveDocument() || compositeOpId.isEmpty()) return false;

    KisNodeSP node = findMobileNode(m_mainWindow->activeView()->image(), id);
    KisLayer *layer = dynamic_cast<KisLayer*>(node.data());
    if (!layer || !layer->colorSpace()
        || !layer->colorSpace()->hasCompositeOp(compositeOpId)) return false;

    const KoCompositeOp *operation = layer->colorSpace()->compositeOp(compositeOpId);
    if (!operation) return false;

    m_mainWindow->viewManager()->nodeManager()->setNodeCompositeOp(node, operation);
    return layer->compositeOpId() == compositeOpId;
}

bool KisMobileBridge::setLayerAlphaLocked(const QString &id, bool locked) const
{
    if (!hasActiveDocument()) return false;

    KisNodeSP node = findMobileNode(m_mainWindow->activeView()->image(), id);
    KisPaintLayer *paintLayer = dynamic_cast<KisPaintLayer*>(node.data());
    KisNodeManager *nodeManager = m_mainWindow->viewManager()->nodeManager();
    if (!paintLayer || !selectSingleMobileNode(nodeManager, node)) return false;

    if (paintLayer->alphaLocked() != locked) nodeManager->toggleAlphaLock();
    return paintLayer->alphaLocked() == locked;
}

bool KisMobileBridge::setLayerInheritAlpha(const QString &id, bool inheritAlpha) const
{
    if (!hasActiveDocument()) return false;

    KisNodeSP node = findMobileNode(m_mainWindow->activeView()->image(), id);
    KisLayer *layer = dynamic_cast<KisLayer*>(node.data());
    KisNodeManager *nodeManager = m_mainWindow->viewManager()->nodeManager();
    if (!layer || !selectSingleMobileNode(nodeManager, node)) return false;

    const bool currentState = !layer->alphaChannelDisabled();
    if (currentState != inheritAlpha) nodeManager->toggleInheritAlpha();
    return !layer->alphaChannelDisabled() == inheritAlpha;
}

bool KisMobileBridge::setLayerOpacity(const QString &id, qreal opacityPercent) const
{
    if (!hasActiveDocument()) return false;
    KisNodeSP node = findMobileNode(m_mainWindow->activeView()->image(), id);
    if (!node) return false;
    const int opacity = qBound(0, qRound(qBound<qreal>(0.0, opacityPercent, 100.0) * 2.55), 255);
    m_mainWindow->viewManager()->nodeManager()->setNodeOpacity(node, opacity);
    return true;
}

bool KisMobileBridge::setLayerLocked(const QString &id, bool locked) const
{
    if (!hasActiveDocument()) return false;
    KisNodeSP node = findMobileNode(m_mainWindow->activeView()->image(), id);
    KisNodeManager *nodeManager = m_mainWindow->viewManager()->nodeManager();
    if (!node || !selectSingleMobileNode(nodeManager, node)) return false;

    if (node->userLocked() != locked) nodeManager->toggleLock();
    return node->userLocked() == locked;
}

bool KisMobileBridge::raiseLayer(const QString &id) const
{
    if (!activateLayer(id)) return false;
    m_mainWindow->viewManager()->nodeManager()->raiseNode();
    return true;
}

bool KisMobileBridge::lowerLayer(const QString &id) const
{
    if (!activateLayer(id)) return false;
    m_mainWindow->viewManager()->nodeManager()->lowerNode();
    return true;
}
