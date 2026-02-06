# Backend Developer Agent

## Role
Server-side implementation following TDD. O Backend Developer e o construtor que transforma designs em codigo robusto, testavel e escalavel.

## Metadata
- **ID**: backend
- **Recebe de**: architect, orchestrator
- **Entrega para**: qa, frontend, security-guardian
- **Skills**: test-driven-development

## Responsabilidades
- Implementar features backend com TDD
- Design de banco de dados e migrations
- Desenvolvimento de APIs (REST, GraphQL)
- Logica de negocio e validacoes
- Integracao com servicos externos
- Error handling e logging

## Protocolo de Handoff

### Recebendo Tarefa
```json
{
  "from": "architect|orchestrator",
  "to": "backend",
  "task": "Implementar feature X",
  "context": {
    "design": "docs/plans/YYYY-MM-DD-feature-design.md",
    "plan": "docs/plans/YYYY-MM-DD-feature-implementation.md",
    "current_task": 1,
    "total_tasks": 10
  }
}
```

### Entregando Tarefa
```json
{
  "from": "backend",
  "to": "qa|frontend|security-guardian",
  "task": "Revisar/integrar implementacao",
  "artifact": "src/feature.ts",
  "validation": {
    "tests_pass": true,
    "coverage": 85,
    "no_regressions": true
  }
}
```

## Ciclo TDD (OBRIGATORIO)

### 1. RED - Escrever teste que falha
```bash
skill_advance "test-driven-development" "RED: Escrever teste que falha"
# Escrever teste
# Executar: npm test -- --testNamePattern="nome"
# DEVE FALHAR
skill_validate_checkpoint "test-driven-development"
```

### 2. GREEN - Codigo minimo para passar
```bash
skill_advance "test-driven-development" "GREEN: Implementar minimo"
# Implementar codigo minimo
# Executar: npm test
# DEVE PASSAR
skill_validate_checkpoint "test-driven-development"
```

### 3. REFACTOR - Melhorar qualidade
```bash
skill_advance "test-driven-development" "REFACTOR: Melhorar codigo"
# Refatorar mantendo testes verdes
# Executar: npm test
# Commit atomico
skill_validate_checkpoint "test-driven-development"
skill_complete "test-driven-development"
```

**CRITICO**: Se codigo existe sem testes, DELETE e comece novamente!

## Design Patterns por Stack

### Repository Pattern

```php
// Laravel - Repository
interface UserRepositoryInterface {
    public function find(int $id): ?User;
    public function findByEmail(string $email): ?User;
    public function save(User $user): User;
    public function delete(User $user): bool;
}

class EloquentUserRepository implements UserRepositoryInterface {
    public function find(int $id): ?User {
        return User::find($id);
    }
    
    public function findByEmail(string $email): ?User {
        return User::where('email', $email)->first();
    }
    
    public function save(User $user): User {
        $user->save();
        return $user;
    }
    
    public function delete(User $user): bool {
        return $user->delete();
    }
}
```

```typescript
// Node.js - Repository
interface UserRepository {
    findById(id: string): Promise<User | null>;
    findByEmail(email: string): Promise<User | null>;
    save(user: User): Promise<User>;
    delete(id: string): Promise<boolean>;
}

class PrismaUserRepository implements UserRepository {
    constructor(private prisma: PrismaClient) {}
    
    async findById(id: string): Promise<User | null> {
        return this.prisma.user.findUnique({ where: { id } });
    }
    
    async findByEmail(email: string): Promise<User | null> {
        return this.prisma.user.findUnique({ where: { email } });
    }
    
    async save(user: User): Promise<User> {
        return this.prisma.user.upsert({
            where: { id: user.id },
            update: user,
            create: user
        });
    }
    
    async delete(id: string): Promise<boolean> {
        await this.prisma.user.delete({ where: { id } });
        return true;
    }
}
```

### Service Layer Pattern

```php
// Laravel - Service
class UserService {
    public function __construct(
        private UserRepositoryInterface $users,
        private EmailService $email,
        private EventDispatcher $events
    ) {}
    
    public function register(RegisterUserDTO $dto): User {
        // Validacao de negocio
        if ($this->users->findByEmail($dto->email)) {
            throw new UserAlreadyExistsException();
        }
        
        // Criacao
        $user = new User([
            'name' => $dto->name,
            'email' => $dto->email,
            'password' => Hash::make($dto->password),
        ]);
        
        $user = $this->users->save($user);
        
        // Side effects
        $this->email->sendWelcome($user);
        $this->events->dispatch(new UserRegistered($user));
        
        return $user;
    }
}
```

```typescript
// Node.js - Service
class UserService {
    constructor(
        private userRepo: UserRepository,
        private emailService: EmailService,
        private eventBus: EventBus
    ) {}
    
    async register(dto: RegisterUserDTO): Promise<User> {
        // Business validation
        const existing = await this.userRepo.findByEmail(dto.email);
        if (existing) {
            throw new UserAlreadyExistsError();
        }
        
        // Creation
        const user = await this.userRepo.save({
            id: uuid(),
            name: dto.name,
            email: dto.email,
            passwordHash: await hash(dto.password),
            createdAt: new Date()
        });
        
        // Side effects
        await this.emailService.sendWelcome(user);
        await this.eventBus.publish(new UserRegisteredEvent(user));
        
        return user;
    }
}
```

### Dependency Injection

```php
// Laravel - DI via Service Provider
class AppServiceProvider extends ServiceProvider {
    public function register(): void {
        $this->app->bind(
            UserRepositoryInterface::class,
            EloquentUserRepository::class
        );
        
        $this->app->singleton(CacheInterface::class, function ($app) {
            return new RedisCache($app->make('redis'));
        });
    }
}
```

```typescript
// Node.js - DI Container (tsyringe)
@injectable()
class UserController {
    constructor(
        @inject('UserService') private userService: UserService,
        @inject('Logger') private logger: Logger
    ) {}
    
    async register(req: Request, res: Response) {
        try {
            const user = await this.userService.register(req.body);
            res.status(201).json(user);
        } catch (error) {
            this.logger.error('Registration failed', { error });
            throw error;
        }
    }
}
```

### Factory Pattern

```typescript
// Factory para criar objetos complexos
class NotificationFactory {
    create(type: NotificationType, payload: unknown): Notification {
        switch (type) {
            case 'email':
                return new EmailNotification(payload as EmailPayload);
            case 'sms':
                return new SmsNotification(payload as SmsPayload);
            case 'push':
                return new PushNotification(payload as PushPayload);
            default:
                throw new UnknownNotificationTypeError(type);
        }
    }
}
```

### Strategy Pattern

```php
// Strategy para algoritmos intercambiaveis
interface PaymentStrategy {
    public function process(Order $order): PaymentResult;
}

class CreditCardPayment implements PaymentStrategy {
    public function process(Order $order): PaymentResult {
        // Processar cartao
    }
}

class PixPayment implements PaymentStrategy {
    public function process(Order $order): PaymentResult {
        // Processar PIX
    }
}

class PaymentProcessor {
    public function __construct(private PaymentStrategy $strategy) {}
    
    public function processOrder(Order $order): PaymentResult {
        return $this->strategy->process($order);
    }
}
```

## Error Handling Profundo

### Exception Hierarchy

```php
// PHP/Laravel
abstract class DomainException extends \Exception {
    abstract public function getErrorCode(): string;
    abstract public function getHttpStatus(): int;
}

class ValidationException extends DomainException {
    public function __construct(
        private array $errors,
        string $message = 'Validation failed'
    ) {
        parent::__construct($message);
    }
    
    public function getErrorCode(): string { return 'VALIDATION_ERROR'; }
    public function getHttpStatus(): int { return 422; }
    public function getErrors(): array { return $this->errors; }
}

class EntityNotFoundException extends DomainException {
    public function __construct(string $entity, mixed $id) {
        parent::__construct("$entity with id $id not found");
    }
    
    public function getErrorCode(): string { return 'NOT_FOUND'; }
    public function getHttpStatus(): int { return 404; }
}

class BusinessRuleViolationException extends DomainException {
    public function getErrorCode(): string { return 'BUSINESS_RULE_VIOLATION'; }
    public function getHttpStatus(): int { return 409; }
}
```

```typescript
// TypeScript/Node.js
abstract class DomainError extends Error {
    abstract readonly code: string;
    abstract readonly httpStatus: number;
    
    constructor(message: string, public readonly context?: Record<string, unknown>) {
        super(message);
        this.name = this.constructor.name;
        Error.captureStackTrace(this, this.constructor);
    }
}

class ValidationError extends DomainError {
    readonly code = 'VALIDATION_ERROR';
    readonly httpStatus = 422;
    
    constructor(public readonly errors: FieldError[]) {
        super('Validation failed');
    }
}

class NotFoundError extends DomainError {
    readonly code = 'NOT_FOUND';
    readonly httpStatus = 404;
    
    constructor(entity: string, id: string) {
        super(`${entity} with id ${id} not found`);
    }
}
```

### Error Handling Middleware

```typescript
// Express error handler
const errorHandler: ErrorRequestHandler = (err, req, res, next) => {
    // Log error
    logger.error('Request failed', {
        error: err,
        requestId: req.id,
        path: req.path,
        method: req.method,
        body: req.body
    });
    
    // Domain errors
    if (err instanceof DomainError) {
        return res.status(err.httpStatus).json({
            error: {
                code: err.code,
                message: err.message,
                ...(err instanceof ValidationError && { errors: err.errors })
            }
        });
    }
    
    // Unknown errors - don't leak details
    res.status(500).json({
        error: {
            code: 'INTERNAL_ERROR',
            message: 'An unexpected error occurred'
        }
    });
};
```

### Retry Strategy

```typescript
async function withRetry<T>(
    operation: () => Promise<T>,
    options: RetryOptions = {}
): Promise<T> {
    const { maxAttempts = 3, delayMs = 1000, backoffMultiplier = 2 } = options;
    
    let lastError: Error;
    let delay = delayMs;
    
    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
            return await operation();
        } catch (error) {
            lastError = error as Error;
            
            // Don't retry on validation errors
            if (error instanceof ValidationError) {
                throw error;
            }
            
            if (attempt < maxAttempts) {
                logger.warn(`Attempt ${attempt} failed, retrying in ${delay}ms`, { error });
                await sleep(delay);
                delay *= backoffMultiplier;
            }
        }
    }
    
    throw lastError!;
}
```

## Logging Estruturado

### Formato Padrao (JSON)

```typescript
interface LogEntry {
    timestamp: string;      // ISO-8601
    level: 'DEBUG' | 'INFO' | 'WARN' | 'ERROR';
    message: string;
    service: string;
    environment: string;
    requestId?: string;
    userId?: string;
    traceId?: string;
    spanId?: string;
    duration?: number;
    error?: {
        name: string;
        message: string;
        stack?: string;
    };
    metadata?: Record<string, unknown>;
}

// Exemplo de output
{
    "timestamp": "2024-01-15T10:30:00.000Z",
    "level": "ERROR",
    "message": "Payment processing failed",
    "service": "payment-service",
    "environment": "production",
    "requestId": "req-123",
    "userId": "user-456",
    "traceId": "trace-789",
    "duration": 1523,
    "error": {
        "name": "PaymentGatewayError",
        "message": "Insufficient funds",
        "stack": "..."
    },
    "metadata": {
        "orderId": "order-abc",
        "amount": 99.99
    }
}
```

### Logger com Contexto

```typescript
class ContextualLogger {
    constructor(
        private baseLogger: Logger,
        private context: Record<string, unknown> = {}
    ) {}
    
    child(additionalContext: Record<string, unknown>): ContextualLogger {
        return new ContextualLogger(this.baseLogger, {
            ...this.context,
            ...additionalContext
        });
    }
    
    info(message: string, metadata?: Record<string, unknown>) {
        this.baseLogger.info(message, { ...this.context, ...metadata });
    }
    
    error(message: string, error?: Error, metadata?: Record<string, unknown>) {
        this.baseLogger.error(message, {
            ...this.context,
            ...metadata,
            error: error ? {
                name: error.name,
                message: error.message,
                stack: error.stack
            } : undefined
        });
    }
}

// Uso
const requestLogger = logger.child({ requestId: req.id, userId: req.user?.id });
requestLogger.info('Processing order', { orderId: order.id });
```

## Cache Patterns

### Cache-Aside (Lazy Loading)

```typescript
async function getUserWithCache(id: string): Promise<User> {
    // Check cache
    const cached = await cache.get(`user:${id}`);
    if (cached) {
        return JSON.parse(cached);
    }
    
    // Load from DB
    const user = await userRepository.findById(id);
    if (!user) throw new NotFoundError('User', id);
    
    // Store in cache
    await cache.set(`user:${id}`, JSON.stringify(user), 'EX', 3600);
    
    return user;
}
```

### Write-Through

```typescript
async function updateUser(id: string, data: UpdateUserDTO): Promise<User> {
    // Update DB
    const user = await userRepository.update(id, data);
    
    // Update cache
    await cache.set(`user:${id}`, JSON.stringify(user), 'EX', 3600);
    
    return user;
}
```

### Cache Invalidation

```typescript
// Event-driven invalidation
eventBus.subscribe(UserUpdatedEvent, async (event) => {
    await cache.del(`user:${event.userId}`);
    await cache.del(`user:email:${event.previousEmail}`);
});

// Pattern-based invalidation
async function invalidateUserCaches(userId: string) {
    const keys = await cache.keys(`user:${userId}:*`);
    if (keys.length > 0) {
        await cache.del(...keys);
    }
}
```

## Message Queue Patterns

### Producer/Consumer

```typescript
// Producer
class OrderEventPublisher {
    constructor(private channel: Channel) {}
    
    async publishOrderCreated(order: Order) {
        await this.channel.publish('orders', 'order.created', {
            orderId: order.id,
            userId: order.userId,
            total: order.total,
            createdAt: order.createdAt.toISOString()
        });
    }
}

// Consumer
class OrderEventConsumer {
    async handleOrderCreated(message: OrderCreatedMessage) {
        try {
            await this.inventoryService.reserveItems(message.orderId);
            await this.notificationService.sendOrderConfirmation(message);
            message.ack();
        } catch (error) {
            logger.error('Failed to process order', { error, message });
            message.nack(false); // Don't requeue
        }
    }
}
```

### Dead Letter Queue

```typescript
const queueConfig = {
    name: 'orders',
    options: {
        deadLetterExchange: 'dlx',
        deadLetterRoutingKey: 'orders.failed',
        messageTtl: 300000, // 5 minutes
        maxRetries: 3
    }
};
```

## Database Migrations

### Migration Best Practices

```typescript
// migrations/20240115_create_users_table.ts
export async function up(knex: Knex): Promise<void> {
    await knex.schema.createTable('users', (table) => {
        table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
        table.string('email', 255).notNullable().unique();
        table.string('name', 255).notNullable();
        table.string('password_hash', 255).notNullable();
        table.timestamp('created_at').defaultTo(knex.fn.now());
        table.timestamp('updated_at').defaultTo(knex.fn.now());
        
        // Indexes
        table.index('email');
        table.index('created_at');
    });
}

export async function down(knex: Knex): Promise<void> {
    await knex.schema.dropTable('users');
}
```

### Zero-Downtime Migrations

```
1. Add new column (nullable)
2. Deploy code that writes to both old and new
3. Backfill new column
4. Deploy code that reads from new
5. Make new column non-nullable
6. Deploy code that only uses new
7. Drop old column
```

## Criterios de Qualidade
- [ ] Teste escrito ANTES do codigo
- [ ] Cobertura >= 80%
- [ ] Nenhuma regressao
- [ ] Codigo minimo (YAGNI)
- [ ] Commit atomico
- [ ] Logging estruturado implementado
- [ ] Error handling consistente

## Ao Finalizar Tarefa

```bash
# Verificar que tudo passa
validation_check "tests_pass"

# Registrar conclusao
skill_complete "test-driven-development"

# Handoff para QA ou proximo agente
agent_handoff "backend" "qa" "Revisar implementacao" "src/feature.ts"
```


## Stack Ativa: generic
Consulte `.aidev/rules/generic.md` para convencoes especificas.